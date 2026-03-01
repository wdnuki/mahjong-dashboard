# Mahjong Dashboard

麻雀の半荘成績を可視化するダッシュボード。

## アーキテクチャ

```
Flutter Web (Firebase Hosting)
    ↓ HTTP GET
GAS Web App (Google Apps Script)
    ↓ BigQuery Advanced Service
BigQuery: mahjonganalyzer.MM.J_HANCHANS_D
```

## ディレクトリ構成

```
mahjong-dashboard/
├── flutter_app/    # Flutter Web フロントエンド
├── gas_api/        # GAS API (clasp + TypeScript)
├── docs/           # 設計書・仕様書
├── deploy.sh       # 一括ビルド・デプロイスクリプト
├── firebase.json   # Firebase Hosting 設定
└── .firebaserc     # Firebase プロジェクト設定
```

## クイックスタート

### 一括デプロイ（推奨）

```bash
# Firebase CI トークンをファイルに保存（初回のみ）
firebase login:ci > .firebase_token   # 表示されたトークンをコピーして保存

# 全体デプロイ（GAS + Flutter + Firebase）
./deploy.sh

# GAS のみ
./deploy.sh --gas-only

# Flutter + Firebase のみ
./deploy.sh --flutter-only
```

### 手動デプロイ: GAS API

```bash
cd gas_api
npm install
npm run build          # TypeScript → JS (dist/)
cp appsscript.json dist/
clasp push --force
clasp deploy -i "DEPLOYMENT_ID"
```

### 手動デプロイ: Flutter Web

```bash
cd flutter_app
flutter pub get
flutter build web \
  --dart-define=API_BASE_URL=https://script.google.com/macros/s/DEPLOYMENT_ID/exec \
  --base-href /
firebase deploy --only hosting --token "$(cat .firebase_token)"
```

## 環境変数・設定

| 項目 | 場所 | 値 |
|---|---|---|
| GAS Script ID | `gas_api/.clasp.json` | 設定済み |
| Firebase Project | `.firebaserc` | `mahjong-dashboard-e72c9` |
| Firebase Token | `.firebase_token` | gitignore（手動設定） |
| API URL | `deploy.sh` 内の `GAS_API_URL` | 設定済み |

## データソース

- BigQuery テーブル: `mahjonganalyzer.MM.J_HANCHANS_D`
- 取得データ: 半荘成績（プレイヤー、得点、日時など）

## 画面構成

- **半荘一覧** (`HanchanScreen`): 最新の半荘成績一覧
