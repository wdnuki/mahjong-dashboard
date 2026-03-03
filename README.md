# Mahjong Dashboard

麻雀の半荘成績を可視化するダッシュボード。

## アーキテクチャ

```
Flutter Web (Firebase Hosting)
    ↓ HTTP GET /api?type=hanchans
Cloud Functions Gen2 (Node.js 20)
    ↓ BigQuery クライアント
BigQuery: mahjonganalyzer.MM.V_HANCHANS
```

## ディレクトリ構成

```
mahjong-dashboard/
├── flutter_app/    # Flutter Web フロントエンド
├── functions/      # Cloud Functions API (TypeScript + esbuild)
├── gas_api/        # 旧 GAS API (参照用・使用停止)
├── docs/           # 設計書・仕様書
├── deploy.sh       # ビルド・デプロイスクリプト
├── Dockerfile      # Docker イメージ (Flutter + Firebase CLI)
├── docker-compose.yml
├── firebase.json   # Firebase Hosting + Functions 設定
└── .firebaserc     # Firebase プロジェクト設定
```

## URL

| 環境 | URL |
|---|---|
| Firebase Hosting | https://mahjong-dashboard-e72c9.web.app |
| API (Hosting 経由) | https://mahjong-dashboard-e72c9.web.app/api |
| API (Functions 直接) | https://us-central1-mahjong-dashboard-e72c9.cloudfunctions.net/api |

## クイックスタート

### 前提条件

- Docker Desktop (Windows)
- `.env` ファイルに `FIREBASE_TOKEN` を設定済み（→ [初回セットアップ](docs/deployment.md)）

### デプロイ（Docker で完結）

```cmd
REM Functions + Hosting を一括デプロイ
docker compose run --rm deploy bash deploy.sh all

REM Functions のみ
docker compose run --rm deploy bash deploy.sh functions

REM Hosting のみ（Flutter ビルド含む）
docker compose run --rm deploy bash deploy.sh hosting
```

## API エンドポイント

`GET /api?type=<type>&year=<year>&month=<month>`

| type | 説明 | 必須パラメータ |
|---|---|---|
| `hanchans` | 半荘一覧 | year, month |
| `ranking` | 投票ランキング | year |
| `participants` | 参加者一覧 | year |
| `relations` | 投票相関 | year |
| `history` | 参加者履歴 | id |

## データソース

| データ | BigQuery プロジェクト | データセット | テーブル/ビュー |
|---|---|---|---|
| 半荘成績 | `mahjonganalyzer` | `MM` | `V_HANCHANS` |
| 投票データ | `mahjonganalyzer` | `kawai_cup` | (未作成) |

## 画面構成

- **半荘一覧** (`HanchanScreen`): 最新の半荘成績一覧
