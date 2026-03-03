#!/usr/bin/env bash
# deploy.sh — Mahjong Dashboard 一括ビルド・デプロイスクリプト
#
# Usage:
#   ./deploy.sh               # GAS + Flutter + Firebase 全デプロイ
#   ./deploy.sh --gas-only    # GAS のみ
#   ./deploy.sh --flutter-only # Flutter ビルド + Firebase デプロイのみ
#   ./deploy.sh --help        # ヘルプを表示

set -euo pipefail

# ─────────────────────────────────────────────
# 設定
# ─────────────────────────────────────────────
GAS_API_URL="https://script.google.com/macros/s/AKfycbyUINv9RI5vQEYSveyr55ViDl5IHuO-X83FguD06D3MyYSxB6EgZ5ZWhPaReGqInLrYRw/exec"
GAS_DEPLOYMENT_ID="AKfycbyUINv9RI5vQEYSveyr55ViDl5IHuO-X83FguD06D3MyYSxB6EgZ5ZWhPaReGqInLrYRw"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAS_DIR="$SCRIPT_DIR/gas_api"
FLUTTER_DIR="$SCRIPT_DIR/flutter_app"
FB_TOKEN=""
FB_AUTH_MODE=""  # "adc" | "token"

# 認証情報の永続保存先（/root/.config は Docker ボリュームでコンテナ再作成後も保持）
CLASP_CREDS_STORE="/root/.config/clasp-creds.json"
FIREBASE_TOKEN_STORE="/root/.config/firebase-ci-token"

# ─────────────────────────────────────────────
# モード判定
# ─────────────────────────────────────────────
MODE="all"
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  cat <<'EOF'

Usage: deploy.sh [MODE]

Modes:
  (none)           GAS + Flutter + Firebase を全デプロイ（デフォルト）
  --gas-only       GAS (Google Apps Script) のみデプロイ
  --flutter-only   Flutter ビルド + Firebase Hosting のみデプロイ
  --help, -h       このヘルプを表示

Authentication:
  clasp (GAS):
    優先順位:
      1. CLASPRC_JSON 環境変数 (base64 エンコード) — CI/CD 推奨
         生成: base64 -w 0 ~/.clasprc.json
      2. /root/.config/clasp-creds.json — 永続ボリューム（前回保存分）
      3. ~/.clasprc.json — 既存ファイル
      4. /workspace/.clasprc.json — ホストからコピー
      5. 対話的ブラウザログイン — ローカルのみ

  Firebase Hosting:
    優先順位:
      1. GOOGLE_APPLICATION_CREDENTIALS — Service Account JSON パス（推奨）
         docker-compose が自動マウント（.env で設定）
      2. FIREBASE_TOKEN 環境変数 — レガシー CI トークン
      3. /root/.config/firebase-ci-token — 永続ボリューム
      4. .firebase_token ファイル — ワークスペース
      5. 対話的入力 — ローカルのみ

Initial setup:
  bash scripts/setup_auth.sh   # ホストマシンで一度だけ実行

EOF
  exit 0
elif [[ "${1:-}" == "--gas-only" ]]; then
  MODE="gas"
elif [[ "${1:-}" == "--flutter-only" ]]; then
  MODE="flutter"
fi

# ─────────────────────────────────────────────
# ユーティリティ
# ─────────────────────────────────────────────
log()     { echo "[$(TZ='Asia/Tokyo' date '+%H:%M:%S')] $*"; }
section() { echo; echo "═══════════════════════════════════════════"; echo "  $*"; echo "═══════════════════════════════════════════"; }
hr()      { echo "  ──────────────────────────────────────────────────"; }

# ─────────────────────────────────────────────
# clasp トークン有効性チェック
# ─────────────────────────────────────────────
_check_clasp_token_valid() {
  local output exit_code=0
  output=$(cd "$GAS_DIR" && npx clasp list 2>&1) || exit_code=$?
  if echo "$output" | grep -qi "not logged in\|invalid_grant\|token expired\|401\|403\|could not refresh"; then
    return 1
  fi
  return 0
}

# ─────────────────────────────────────────────
# clasp 認証確認
#
# 優先順位:
#   0. CLASPRC_JSON 環境変数 (base64) ← CI/CD
#   1. /root/.config/clasp-creds.json ← 永続ボリューム
#   2. ~/.clasprc.json ← 既存
#   3. /workspace/.clasprc.json ← ホストコピー
#   4. 対話ログイン ← ローカルのみ
# ─────────────────────────────────────────────
ensure_clasp_login() {
  local creds_ok=false

  # 0. CI/CD: CLASPRC_JSON 環境変数 (base64 エンコード)
  if [[ -n "${CLASPRC_JSON:-}" ]]; then
    log "→ CLASPRC_JSON 環境変数からクレデンシャルをデコード"
    mkdir -p "$(dirname "$CLASP_CREDS_STORE")"
    printf '%s' "$CLASPRC_JSON" | base64 --decode > "$HOME/.clasprc.json"
    if ! grep -q '"token"' "$HOME/.clasprc.json" 2>/dev/null; then
      echo
      echo "[ERROR] CLASPRC_JSON のデコード結果に \"token\" フィールドが見つかりません。"
      echo "        以下のコマンドで再生成して Secret を更新してください:"
      echo "        base64 -w 0 ~/.clasprc.json"
      exit 1
    fi
    cp "$HOME/.clasprc.json" "$CLASP_CREDS_STORE"
    log "✓ clasp: CI/CD 環境変数から認証情報を設定"
    creds_ok=true
  fi

  # 1. 永続ボリュームから復元
  if ! $creds_ok && [[ -f "$CLASP_CREDS_STORE" ]] && grep -q '"token"' "$CLASP_CREDS_STORE" 2>/dev/null; then
    cp "$CLASP_CREDS_STORE" "$HOME/.clasprc.json"
    log "✓ clasp: 設定ボリュームから認証情報を復元"
    creds_ok=true
  fi

  # 2. ホームディレクトリの既存ファイル
  if ! $creds_ok && [[ -f "$HOME/.clasprc.json" ]] && grep -q '"token"' "$HOME/.clasprc.json" 2>/dev/null; then
    log "✓ clasp: ログイン済み (~/.clasprc.json)"
    creds_ok=true
  fi

  # 3. ワークスペースにコピーされたファイル
  if ! $creds_ok && [[ -f "$SCRIPT_DIR/.clasprc.json" ]]; then
    cp "$SCRIPT_DIR/.clasprc.json" "$HOME/.clasprc.json"
    log "✓ clasp: .clasprc.json から認証情報を読み込みました"
    creds_ok=true
  fi

  # 認証情報が見つかった場合、永続ボリュームに保存 + トークン有効性チェック
  if $creds_ok; then
    mkdir -p "$(dirname "$CLASP_CREDS_STORE")"
    cp "$HOME/.clasprc.json" "$CLASP_CREDS_STORE"

    log "→ clasp トークンの有効性を確認中..."
    if ! _check_clasp_token_valid; then
      log "⚠ clasp トークンが期限切れまたは無効です。認証情報をクリアします。"
      rm -f "$HOME/.clasprc.json" "$CLASP_CREDS_STORE"
      creds_ok=false
    else
      log "✓ clasp: トークン有効"
    fi
  fi

  if $creds_ok; then
    return
  fi

  # 4. 認証情報が見つからない / 無効 → 案内
  echo
  log "⚠ clasp 認証情報が見つかりません（または期限切れ）"
  hr
  echo
  echo "  【解決方法を選択してください】"
  echo
  echo "  A) CI/CD 環境 (GitHub Actions 等):"
  echo "     CLASPRC_JSON Secret を更新してください:"
  echo "     ホストマシンで: npx clasp login && base64 -w 0 ~/.clasprc.json"
  echo
  echo "  B) Docker ローカル環境:"
  echo "     ホストマシンで clasp login 後、コンテナを再起動してください:"
  echo "       cd $GAS_DIR && npx clasp login"
  echo "       docker-compose run --rm deploy bash deploy.sh"
  echo
  echo "  C) 対話ターミナルから直接実行 (VS Code ターミナル等):"

  if [ -t 0 ] && [ -t 1 ]; then
    echo "     ブラウザを開いて認証します..."
    hr
    echo
    (cd "$GAS_DIR" && npx clasp login)

    if ! grep -q '"token"' "$HOME/.clasprc.json" 2>/dev/null; then
      echo "[ERROR] ログインが完了しませんでした。"
      exit 1
    fi

    mkdir -p "$(dirname "$CLASP_CREDS_STORE")"
    cp "$HOME/.clasprc.json" "$CLASP_CREDS_STORE"
    log "✓ clasp: 認証情報を設定ボリュームに保存しました（次回から自動で使用されます）"
  else
    echo "     (非対話環境のため自動実行不可。上記 A または B を使用してください)"
    hr
    exit 1
  fi
}

# ─────────────────────────────────────────────
# Firebase 認証確認
#
# 優先順位:
#   0. GOOGLE_APPLICATION_CREDENTIALS (Service Account JSON) ← 推奨
#   1. FIREBASE_TOKEN 環境変数 ← レガシー後方互換
#   2. /root/.config/firebase-ci-token ← 永続ボリューム
#   3. .firebase_token ← ワークスペース
#   4. 対話的入力 ← ローカルのみ
# ─────────────────────────────────────────────
ensure_firebase_auth() {
  # 0. Service Account via ADC（推奨）
  if [[ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
    if [[ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]]; then
      echo
      echo "[ERROR] GOOGLE_APPLICATION_CREDENTIALS が設定されていますが、ファイルが見つかりません:"
      echo "        $GOOGLE_APPLICATION_CREDENTIALS"
      echo
      echo "  Docker ローカル: docker-compose.yml のボリュームマウントを確認してください。"
      echo "    GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH が .env に設定されているか確認:"
      echo "    cat .env | grep GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH"
      echo
      echo "  CI/CD: GCP_SERVICE_ACCOUNT_KEY Secret から SA JSON を展開してください:"
      echo "    echo \"\$GCP_SERVICE_ACCOUNT_KEY\" | base64 -d > /tmp/sa-key.json"
      echo "    export GOOGLE_APPLICATION_CREDENTIALS=/tmp/sa-key.json"
      exit 1
    fi
    if ! python3 -c "
import json, sys
d = json.load(open('$GOOGLE_APPLICATION_CREDENTIALS'))
assert 'private_key' in d, 'private_key field missing'
" 2>/dev/null; then
      echo
      echo "[ERROR] GOOGLE_APPLICATION_CREDENTIALS のファイルが有効な Service Account JSON ではありません。"
      echo "        GCP Console → IAM → サービスアカウント → キーを作成 → JSON"
      exit 1
    fi
    FB_AUTH_MODE="adc"
    log "✓ Firebase: GOOGLE_APPLICATION_CREDENTIALS (Service Account) を使用"
    log "  ファイル: $GOOGLE_APPLICATION_CREDENTIALS"
    return
  fi

  # 1. 環境変数 FIREBASE_TOKEN（レガシー後方互換）
  if [[ -n "${FIREBASE_TOKEN:-}" ]]; then
    FB_TOKEN="$FIREBASE_TOKEN"
    FB_AUTH_MODE="token"
    log "✓ Firebase: 環境変数 FIREBASE_TOKEN を使用（非推奨。Service Account への移行を推奨）"
    return
  fi

  # 2. 永続ボリューム
  if [[ -f "$FIREBASE_TOKEN_STORE" ]] && [[ -s "$FIREBASE_TOKEN_STORE" ]]; then
    FB_TOKEN="$(cat "$FIREBASE_TOKEN_STORE")"
    FB_AUTH_MODE="token"
    log "✓ Firebase: 設定ボリュームからトークンを復元（非推奨）"
    return
  fi

  # 3. ワークスペースのトークンファイル
  if [[ -f "$SCRIPT_DIR/.firebase_token" ]]; then
    FB_TOKEN="$(cat "$SCRIPT_DIR/.firebase_token")"
    FB_AUTH_MODE="token"
    log "✓ Firebase: .firebase_token を使用（非推奨）"
    echo "$FB_TOKEN" > "$FIREBASE_TOKEN_STORE"
    return
  fi

  # 4. 認証情報が見つからない → 案内
  echo
  log "⚠ Firebase 認証情報が見つかりません"
  hr
  echo
  echo "  【推奨】Service Account JSON を設定してください:"
  echo "  1. GCP Console → IAM → サービスアカウント → キーを作成 → JSON をダウンロード"
  echo "     https://console.cloud.google.com/iam-admin/serviceaccounts"
  echo "     必要なロール: Firebase Hosting 管理者 (roles/firebasehosting.admin)"
  echo "  2. ホストマシンで: bash scripts/setup_auth.sh"
  echo "     → .env と docker-compose を自動設定します"
  echo
  echo "  【代替】レガシー CI トークン（非推奨）:"
  echo "  ホストマシンで: firebase login:ci"
  echo "  表示されたトークン（1// で始まる）を以下に貼り付けてください:"
  hr
  echo

  read -r FB_TOKEN < /dev/tty

  if [[ -z "$FB_TOKEN" ]]; then
    echo "[ERROR] トークンが入力されませんでした。"
    exit 1
  fi

  FB_AUTH_MODE="token"
  mkdir -p "$(dirname "$FIREBASE_TOKEN_STORE")"
  echo "$FB_TOKEN" > "$FIREBASE_TOKEN_STORE"
  log "✓ Firebase: トークンを設定ボリュームに保存しました（次回から自動で使用されます）"
}

# ─────────────────────────────────────────────
# GAS デプロイ
# ─────────────────────────────────────────────
deploy_gas() {
  section "GAS デプロイ開始"

  ensure_clasp_login

  log "→ npm install"
  (cd "$GAS_DIR" && npm install)

  log "→ TypeScript ビルド (tsc)"
  (cd "$GAS_DIR" && npm run build)

  log "→ appsscript.json を dist/ にコピー"
  cp "$GAS_DIR/appsscript.json" "$GAS_DIR/dist/"

  log "→ clasp push --force"
  (cd "$GAS_DIR" && npx clasp push --force)

  log "→ clasp deploy (既存デプロイを更新: $GAS_DEPLOYMENT_ID)"
  (cd "$GAS_DIR" && npx clasp deploy -i "$GAS_DEPLOYMENT_ID" -d "deploy $(date '+%Y-%m-%d %H:%M')")

  log "✓ GAS デプロイ完了"
  log "  API URL: $GAS_API_URL"
}

# ─────────────────────────────────────────────
# Flutter ビルド + Firebase デプロイ
# ─────────────────────────────────────────────
deploy_flutter() {
  section "Flutter ビルド開始"

  ensure_firebase_auth

  log "→ flutter pub get"
  (cd "$FLUTTER_DIR" && flutter pub get)

  log "→ flutter build web"
  (cd "$FLUTTER_DIR" && flutter build web \
    --dart-define=API_BASE_URL="$GAS_API_URL" \
    --base-href /)

  log "✓ Flutter ビルド完了"

  section "Firebase Hosting デプロイ開始"

  log "→ firebase deploy --only hosting"
  if [[ "$FB_AUTH_MODE" == "adc" ]]; then
    # Service Account ADC: --token 不要。Firebase CLI が GOOGLE_APPLICATION_CREDENTIALS を自動検出
    local fb_project
    fb_project=$(python3 -c "import json; print(json.load(open('$SCRIPT_DIR/.firebaserc'))['projects']['default'])")
    (cd "$SCRIPT_DIR" && firebase deploy --only hosting \
      --project "$fb_project" \
      --non-interactive)
  else
    # レガシートークン（後方互換）
    (cd "$SCRIPT_DIR" && firebase deploy --only hosting \
      --token "$FB_TOKEN" \
      --non-interactive)
  fi

  log "✓ Firebase デプロイ完了"
  log "  URL: https://mahjong-dashboard-e72c9.web.app"
}

# ─────────────────────────────────────────────
# メイン
# ─────────────────────────────────────────────
section "Mahjong Dashboard デプロイ (mode=$MODE)"
log "開始時刻: $(date)"

case "$MODE" in
  gas)     deploy_gas ;;
  flutter) deploy_flutter ;;
  all)     deploy_gas; deploy_flutter ;;
esac

section "デプロイ完了"
log "終了時刻: $(date)"
