#!/usr/bin/env bash
# deploy.sh — Mahjong Dashboard ビルド・デプロイスクリプト
#
# Usage:
#   bash deploy.sh           # functions + hosting (デフォルト)
#   bash deploy.sh all       # 同上
#   bash deploy.sh functions # Cloud Functions のみ
#   bash deploy.sh hosting   # Flutter ビルド + Firebase Hosting のみ

set -euo pipefail

MODE="${1:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$SCRIPT_DIR/flutter_app"
API_URL="https://mahjong-dashboard-e72c9.web.app/api"

log() { echo "[$(TZ='Asia/Tokyo' date '+%H:%M:%S')] $*"; }

deploy_functions() {
  log "→ functions: npm install"
  (cd "$SCRIPT_DIR/functions" && npm install)

  # Firebase CLI のバックエンド仕様検出をサブプロセスではなくファイル経由で行う。
  # (WSL2 環境では CLI のサブプロセス起動が失敗するため事前生成で回避)
  log "→ functions: generate functions.yaml"
  (cd "$SCRIPT_DIR/functions" && \
    FUNCTIONS_MANIFEST_OUTPUT_PATH=./functions.yaml \
    node_modules/.bin/firebase-functions .)

  log "→ firebase deploy --only functions"
  (cd "$SCRIPT_DIR" && firebase deploy --only functions --non-interactive --force)

  rm -f "$SCRIPT_DIR/functions/functions.yaml"
  log "✓ Cloud Functions デプロイ完了"
}

deploy_hosting() {
  log "→ flutter pub get"
  (cd "$FLUTTER_DIR" && flutter pub get)

  log "→ flutter build web"
  (cd "$FLUTTER_DIR" && flutter build web \
    --dart-define=API_BASE_URL="$API_URL" \
    --base-href /)

  log "→ firebase deploy --only hosting"
  (cd "$SCRIPT_DIR" && firebase deploy --only hosting --non-interactive)
  log "✓ Firebase Hosting デプロイ完了"
}

case "$MODE" in
  all)       deploy_functions; deploy_hosting ;;
  functions) deploy_functions ;;
  hosting)   deploy_hosting ;;
  *)
    echo "Usage: deploy.sh [all|functions|hosting]"
    exit 1
    ;;
esac

log "完了: https://mahjong-dashboard-e72c9.web.app"
