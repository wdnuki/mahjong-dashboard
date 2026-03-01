#!/usr/bin/env bash
# deploy.sh — Mahjong Dashboard 一括ビルド・デプロイスクリプト
# Usage:
#   ./deploy.sh               # GAS + Flutter + Firebase 全デプロイ
#   ./deploy.sh --gas-only    # GAS のみ
#   ./deploy.sh --flutter-only # Flutter ビルド + Firebase デプロイのみ

set -euo pipefail

# ─────────────────────────────────────────────
# 設定
# ─────────────────────────────────────────────
GAS_API_URL="https://script.google.com/macros/s/AKfycbyUINv9RI5vQEYSveyr55ViDl5IHuO-X83FguD06D3MyYSxB6EgZ5ZWhPaReGqInLrYRw/exec"
GAS_DEPLOYMENT_ID="AKfycbyUINv9RI5vQEYSveyr55ViDl5IHuO-X83FguD06D3MyYSxB6EgZ5ZWhPaReGqInLrYRw"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAS_DIR="$SCRIPT_DIR/gas_api"
FLUTTER_DIR="$SCRIPT_DIR/flutter_app"

# Firebase トークン: 環境変数 FIREBASE_TOKEN か .firebase_token ファイル
if [[ -n "${FIREBASE_TOKEN:-}" ]]; then
  FB_TOKEN="$FIREBASE_TOKEN"
elif [[ -f "$SCRIPT_DIR/.firebase_token" ]]; then
  FB_TOKEN="$(cat "$SCRIPT_DIR/.firebase_token")"
else
  echo "[ERROR] Firebase トークンが見つかりません。"
  echo "  .firebase_token ファイルを作成するか、FIREBASE_TOKEN 環境変数を設定してください。"
  echo "  取得方法: firebase login:ci"
  exit 1
fi

# ─────────────────────────────────────────────
# モード判定
# ─────────────────────────────────────────────
MODE="all"
if [[ "${1:-}" == "--gas-only" ]]; then
  MODE="gas"
elif [[ "${1:-}" == "--flutter-only" ]]; then
  MODE="flutter"
fi

# ─────────────────────────────────────────────
# ユーティリティ
# ─────────────────────────────────────────────
log() { echo "[$(date '+%H:%M:%S')] $*"; }
section() { echo; echo "═══════════════════════════════════════════"; echo "  $*"; echo "═══════════════════════════════════════════"; }

# ─────────────────────────────────────────────
# GAS デプロイ
# ─────────────────────────────────────────────
deploy_gas() {
  section "GAS デプロイ開始"

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

  log "→ flutter pub get"
  (cd "$FLUTTER_DIR" && flutter pub get)

  log "→ flutter build web"
  (cd "$FLUTTER_DIR" && flutter build web \
    --dart-define=API_BASE_URL="$GAS_API_URL" \
    --base-href /)

  log "✓ Flutter ビルド完了"

  section "Firebase Hosting デプロイ開始"

  log "→ firebase deploy --only hosting"
  (cd "$SCRIPT_DIR" && firebase deploy --only hosting \
    --token "$FB_TOKEN" \
    --non-interactive)

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
