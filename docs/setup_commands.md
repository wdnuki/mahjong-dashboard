# セットアップ手順・コマンド記録

## 概要

BigQuery `mahjonganalyzer.MM.V_HANCHANS` から半荘データを取得し、Flutter Web アプリで一覧表示する。

**スタック:**
```
Flutter Web → Cloud Functions API (/api?type=hanchans) → BigQuery (mahjonganalyzer.MM.V_HANCHANS)
```

---

## 主要設定値

| 項目 | 値 |
|---|---|
| Firebase プロジェクト ID | `mahjong-dashboard-e72c9` |
| Firebase Hosting URL | `https://mahjong-dashboard-e72c9.web.app` |
| Cloud Functions URL | `https://us-central1-mahjong-dashboard-e72c9.cloudfunctions.net/api` |
| BigQuery プロジェクト (半荘データ) | `mahjonganalyzer` |
| BigQuery データセット | `MM` |
| BigQuery ビュー | `V_HANCHANS` |
| Cloud Functions サービスアカウント | `989043044664-compute@developer.gserviceaccount.com` |

---

## デプロイコマンド（Docker 完結）

```cmd
REM 一括デプロイ
docker compose run --rm deploy bash deploy.sh all

REM Functions のみ
docker compose run --rm deploy bash deploy.sh functions

REM Hosting のみ
docker compose run --rm deploy bash deploy.sh hosting
```

---

## 検証コマンド（WSL / gcloud CLI）

gcloud は WSL に導入済み。認証後は Claude Code から直接実行可能。

### 認証（初回・PC 買い替え時）

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project mahjonganalyzer
```

### BigQuery 確認

```bash
# データセット一覧
bq ls --project_id=mahjonganalyzer

# ビュー確認
bq show mahjonganalyzer:MM.V_HANCHANS

# データ取得テスト
bq query --nouse_legacy_sql \
  'SELECT * FROM `mahjonganalyzer.MM.V_HANCHANS` LIMIT 3'
```

### Cloud Functions 確認

```bash
# デプロイ済み Functions 一覧
gcloud functions list --project=mahjong-dashboard-e72c9

# サービスアカウント確認
gcloud functions describe api --region=us-central1 --project=mahjong-dashboard-e72c9 --gen2 \
  --format="value(serviceConfig.serviceAccountEmail)"
```

### IAM 権限確認・付与

```cmd
REM Windows cmd で実行
gcloud projects get-iam-policy mahjonganalyzer --format=json | findstr "989043044664"

REM 権限付与（初回セットアップ済み）
gcloud projects add-iam-policy-binding mahjonganalyzer --member="serviceAccount:989043044664-compute@developer.gserviceaccount.com" --role="roles/bigquery.jobUser"
gcloud projects add-iam-policy-binding mahjonganalyzer --member="serviceAccount:989043044664-compute@developer.gserviceaccount.com" --role="roles/bigquery.dataViewer"
```

---

## API エンドポイント動作確認

```
# 半荘一覧
https://mahjong-dashboard-e72c9.web.app/api?type=hanchans&year=2026&month=3

# (将来) 投票ランキング
https://mahjong-dashboard-e72c9.web.app/api?type=ranking&year=2025
```
