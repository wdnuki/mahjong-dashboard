# デプロイ手順

## 概要

デプロイはすべて **Docker で完結**する。ホスト PC に Flutter / Node.js は不要。

```
ホスト (Windows)
└── Docker Desktop
    └── mahjong-dashboard-local イメージ
        ├── Flutter 3.29.2
        └── Firebase CLI 15.8.0
```

---

## 前提条件

| ツール | インストール先 | 用途 |
|---|---|---|
| Docker Desktop | ホスト (Windows) | ビルド・デプロイ実行 |
| gcloud CLI | ホスト (Windows) または WSL | IAM 設定・初回セットアップのみ |

---

## 初回セットアップ（PC 買い替え時も同じ手順）

### 1. リポジトリをクローン

```cmd
git clone <repo-url> mahjong-dashboard
cd mahjong-dashboard
```

### 2. Docker イメージをビルド

```cmd
docker compose build
```

### 3. FIREBASE_TOKEN を取得

ホスト (Windows cmd) で実行：

```cmd
firebase login:ci
```

ブラウザでログイン → 表示されたトークンをコピー。

### 4. .env ファイルを作成

```cmd
copy .env.example .env
```

`.env` を開いて `FIREBASE_TOKEN=` の後にトークンを貼り付ける：

```
FIREBASE_TOKEN=1//0e...（firebase login:ci で取得したトークン）
```

### 5. Cloud Functions のサービスアカウントに BigQuery 権限を付与（初回のみ）

```cmd
gcloud functions describe api --region=us-central1 --project=mahjong-dashboard-e72c9 --gen2 --format="value(serviceConfig.serviceAccountEmail)"
```

表示されたサービスアカウント (`<SA>@developer.gserviceaccount.com`) を使って：

```cmd
gcloud projects add-iam-policy-binding mahjonganalyzer --member="serviceAccount:<SA>" --role="roles/bigquery.jobUser"
gcloud projects add-iam-policy-binding mahjonganalyzer --member="serviceAccount:<SA>" --role="roles/bigquery.dataViewer"
```

> 現在設定済み: `989043044664-compute@developer.gserviceaccount.com`

---

## デプロイ

### 一括デプロイ（Functions + Hosting）

```cmd
docker compose run --rm deploy bash deploy.sh all
```

### Functions のみ

```cmd
docker compose run --rm deploy bash deploy.sh functions
```

### Hosting のみ（Flutter ビルド + Firebase Hosting）

```cmd
docker compose run --rm deploy bash deploy.sh hosting
```

---

## デプロイ後の確認

### API 動作確認（ブラウザ）

```
https://mahjong-dashboard-e72c9.web.app/api?type=hanchans&year=2026&month=3
```

正常時のレスポンス例：
```json
{
  "year": 2026,
  "data": [
    {
      "hanchan_id": "...",
      "kanri_date": "2026-03-01",
      "nick_name": "...",
      "soten": 25000,
      "point": 3.0,
      "rank": 1
    }
  ]
}
```

### Flutter アプリ確認

```
https://mahjong-dashboard-e72c9.web.app
```

---

## トラブルシューティング

### `FIREBASE_TOKEN` エラー

→ `.env` ファイルに `FIREBASE_TOKEN=...` が設定されているか確認。

### `Timeout after 10000` (Functions)

→ `functions/lib/index.js` が存在しないか古い。Docker 内で `npm run build` が走っているか確認。

### `Access Denied: bigquery.jobs.create`

→ サービスアカウントに `roles/bigquery.jobUser` が付与されているか確認（→ 初回セットアップ Step 5）。

### `Dataset not found in location US`

→ サービスアカウントへの権限付与が完了していないか、BigQuery データセットが存在しない。
