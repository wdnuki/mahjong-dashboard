#!/usr/bin/env bash
# deploy.sh — Mahjong Dashboard ビルド・デプロイスクリプト
#
# Usage:
#   bash deploy.sh               # hosting + mahjong-api (デフォルト)
#   bash deploy.sh all           # 同上
#   bash deploy.sh hosting       # Flutter ビルド + Firebase Hosting のみ
#   bash deploy.sh mahjong-api   # Python Cloud Functions (gcloud) のみ

set -euo pipefail

MODE="${1:-all}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$SCRIPT_DIR/flutter_app"
API_URL="https://mahjong-dashboard-e72c9.web.app/api"

log() { echo "[$(TZ='Asia/Tokyo' date '+%H:%M:%S')] $*"; }

deploy_mahjong_api() {
  log "→ mahjong-api: gcloud functions deploy"
  gcloud functions deploy mahjong-api \
    --gen2 \
    --runtime python311 \
    --region asia-northeast1 \
    --source "$SCRIPT_DIR/mahjong-api" \
    --entry-point app \
    --trigger-http \
    --allow-unauthenticated \
    --quiet
  log "✓ mahjong-api デプロイ完了"
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
  all)          deploy_hosting; deploy_mahjong_api ;;
  hosting)      deploy_hosting ;;
  mahjong-api)  deploy_mahjong_api ;;
  *)
    echo "Usage: deploy.sh [all|hosting|mahjong-api]"
    exit 1
    ;;
esac

log "完了: https://mahjong-dashboard-e72c9.web.app"
