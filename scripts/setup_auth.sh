#!/usr/bin/env bash
# scripts/setup_auth.sh — 初回認証セットアップ
#
# ホストマシン（Docker の外）で一度だけ実行してください。
# Firebase Service Account を準備し、GitHub Actions 用の Secrets 値を出力します。
#
# Usage:
#   bash scripts/setup_auth.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"

# ─────────────────────────────────────────────
# ユーティリティ
# ─────────────────────────────────────────────
log()     { echo "[$(date '+%H:%M:%S')] $*"; }
section() { echo; echo "════════════════════════════════════════════"; echo "  $*"; echo "════════════════════════════════════════════"; }
hr()      { echo "  ────────────────────────────────────────────"; }
ok()      { echo "  ✓ $*"; }
warn()    { echo "  ⚠ $*"; }
err()     { echo "  ✗ [ERROR] $*" >&2; }

# ─────────────────────────────────────────────
# Step 1: Firebase Service Account セットアップ
# ─────────────────────────────────────────────
setup_firebase_credentials() {
  section "Step 1: Firebase Service Account (GCP)"
  echo
  echo "  Firebase Hosting のデプロイに必要な Service Account JSON を準備します。"
  echo
  echo "  【事前準備】GCP Console で Service Account を作成してください："
  echo "  1. https://console.cloud.google.com/iam-admin/serviceaccounts"
  echo "     プロジェクト: mahjong-dashboard-e72c9"
  echo "  2. 「サービスアカウントを作成」"
  echo "     名前例: github-deploy"
  echo "  3. ロールを付与: Firebase Hosting 管理者 (roles/firebasehosting.admin)"
  echo "  4. 「キー」タブ → 「鍵を追加」→ JSON でダウンロード"
  echo
  hr

  local sa_path
  local dest_dir="$HOME/.config"
  local dest="$dest_dir/mahjong-dashboard-sa.json"

  # 既にセットアップ済みかチェック
  if [[ -f "$dest" ]]; then
    echo
    ok "Service Account JSON が既に存在します: $dest"
    echo
    read -r -p "  別のファイルで上書きしますか？ [y/N]: " overwrite
    if [[ "${overwrite:-N}" != "y" ]] && [[ "${overwrite:-N}" != "Y" ]]; then
      echo "  既存のファイルを使用します。"
      _write_env_and_show_secret "$dest"
      return
    fi
  fi

  echo
  read -r -p "  ダウンロードした Service Account JSON のパスを入力: " sa_path

  if [[ ! -f "$sa_path" ]]; then
    err "ファイルが見つかりません: $sa_path"
    exit 1
  fi

  # JSON 検証
  if ! python3 -c "
import json, sys
d = json.load(open('$sa_path'))
assert 'private_key' in d and 'client_email' in d, 'invalid SA JSON'
print(d['client_email'])
" 2>/dev/null; then
    err "有効な Service Account JSON ではありません。"
    err "GCP Console からダウンロードした JSON ファイルか確認してください。"
    exit 1
  fi

  local email
  email=$(python3 -c "import json; print(json.load(open('$sa_path'))['client_email'])")
  ok "Service Account: $email"

  # 標準保存先にコピー
  mkdir -p "$dest_dir"
  cp "$sa_path" "$dest"
  chmod 600 "$dest"
  ok "保存先: $dest"

  _write_env_and_show_secret "$dest"
}

_write_env_and_show_secret() {
  local dest="$1"

  # .env を更新（既存エントリがあれば上書き、なければ追記）
  if [[ -f "$ENV_FILE" ]]; then
    if grep -q '^GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH=' "$ENV_FILE"; then
      sed -i "s|^GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH=.*|GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH=$dest|" "$ENV_FILE"
    else
      echo "GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH=$dest" >> "$ENV_FILE"
    fi
  else
    cp "$PROJECT_ROOT/.env.example" "$ENV_FILE"
    sed -i "s|^GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH=.*|GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH=$dest|" "$ENV_FILE"
  fi
  ok ".env を更新しました"

  # GitHub Actions Secret 用に base64 エンコード
  echo
  section "  GitHub Secret: GCP_SERVICE_ACCOUNT_KEY"
  echo
  echo "  以下の値をコピーして GitHub Actions Secret に登録してください："
  echo "  Secret 名: GCP_SERVICE_ACCOUNT_KEY"
  echo "  Secret 値:"
  echo
  base64 -w 0 "$dest"
  echo
  echo
  ok "Firebase セットアップ完了"
}

# ─────────────────────────────────────────────
# Step 2: 検証
# ─────────────────────────────────────────────
verify_setup() {
  section "Step 2: セットアップ検証"
  echo

  local all_ok=true

  # .env チェック
  if [[ -f "$ENV_FILE" ]]; then
    ok ".env ファイルが存在します"
    local sa_host_path
    sa_host_path=$(grep '^GOOGLE_APPLICATION_CREDENTIALS_HOST_PATH=' "$ENV_FILE" | cut -d= -f2-)
    if [[ -n "$sa_host_path" ]] && [[ -f "$sa_host_path" ]]; then
      ok "Service Account JSON が存在します: $sa_host_path"
    else
      warn "Service Account JSON が見つかりません: $sa_host_path"
      all_ok=false
    fi
  else
    warn ".env が見つかりません"
    all_ok=false
  fi

  echo

  if $all_ok; then
    ok "セットアップ完了！以下のコマンドでデプロイできます："
    echo
    echo "  # イメージをビルド（初回のみ）"
    echo "  docker-compose build"
    echo
    echo "  # 全デプロイ"
    echo "  docker-compose run --rm deploy"
  else
    warn "セットアップが不完全です。上記のエラーを確認してください。"
    exit 1
  fi
}

# ─────────────────────────────────────────────
# メイン
# ─────────────────────────────────────────────
echo
echo "  Mahjong Dashboard — 初回認証セットアップ"
echo "  このスクリプトはホストマシン（Docker の外）で実行してください。"
echo

setup_firebase_credentials
verify_setup

echo
