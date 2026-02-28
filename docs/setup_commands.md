# セットアップ手順・コマンド記録

## 概要

BigQuery `mahjonganalyzer.MM.J_HANCHANS_D` から半荘データを取得し、Flutter Web アプリで一覧表示する。

**スタック:**
```
Flutter Web → GAS API (?type=hanchans) → BigQuery (mahjonganalyzer.MM.J_HANCHANS_D)
```

---

## 1. 前提確認

```bash
# gcloud プロジェクト確認
gcloud config get-value project
# → kaw-ai (GAS/Firebase 用プロジェクト)

# BigQuery データセット MM は mahjonganalyzer プロジェクトにある
# BigQuery Console: https://console.cloud.google.com/bigquery?project=mahjonganalyzer
```

---

## 2. GAS API セットアップ

### 2-1. 依存インストール・ビルド

```bash
cd gas_api
npm install
npm run build
```

### 2-2. clasp ログイン・初期化

```bash
# Google アカウントでログイン
npx clasp login

# .clasp.json にスクリプト ID を設定
# Gas Script ID は https://script.google.com から取得
# または新規作成:
npx clasp create --type webapp --title "mahjong-dashboard-api"
```

### 2-3. GAS へプッシュ・デプロイ

```bash
cd gas_api
npx clasp push
npx clasp deploy --description "initial deploy"
# → デプロイ URL を控えておく (API_BASE_URL として使用)
```

### 2-4. BigQuery Advanced Service の有効化

GAS スクリプトエディタで手動操作が必要:
1. https://script.google.com でスクリプトを開く
2. 「サービス」→「BigQuery API」を追加
3. ID: `BigQuery`、バージョン: `v2`

### 2-5. 動作確認

ブラウザで以下にアクセスして JSON が返ることを確認:
```
https://script.google.com/macros/s/{SCRIPT_ID}/exec?type=hanchans
```

期待レスポンス:
```json
{
  "status": "ok",
  "year": 2026,
  "data": [
    {
      "hanchan_id": "...",
      "line_user_id": "...",
      "soten": 25000,
      "point": 3.0,
      "point_zone": 0.0,
      "rank": 1,
      "created_at": "2026-01-15T10:00:00"
    }
  ]
}
```

---

## 3. Firebase セットアップ

### 3-1. Firebase プロジェクト設定

```bash
# .firebaserc を編集して Firebase プロジェクト ID を設定
# kaw-ai または別のプロジェクト ID

firebase use kaw-ai
```

### 3-2. Firebase ログイン確認

```bash
firebase login
firebase projects:list
```

---

## 4. Flutter アプリ

### 4-1. 依存解決

```bash
cd flutter_app
flutter pub get
```

### 4-2. ローカル動作確認

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://script.google.com/macros/s/{SCRIPT_ID}/exec
```

ランキング画面右上の テーブルアイコン をクリック → 半荘一覧画面に遷移してデータが表示されることを確認。

### 4-3. 本番ビルド

```bash
flutter build web \
  --dart-define=API_BASE_URL=https://script.google.com/macros/s/{SCRIPT_ID}/exec \
  --base-href /
```

---

## 5. Firebase Hosting デプロイ

```bash
cd ..  # mahjong-dashboard ルートへ
firebase deploy --only hosting
```

---

## 6. 変更ファイル一覧

| ファイル | 内容 |
|---|---|
| `gas_api/src/bigquery.ts` | `MM_PROJECT_ID='mahjonganalyzer'` 追加、`fetchHanchans()` 追加 |
| `gas_api/src/main.ts` | `case 'hanchans':` 追加 |
| `flutter_app/lib/models/hanchan_entry.dart` | 新規: HanchanEntry モデル |
| `flutter_app/lib/services/api_service.dart` | `_get()` を optional year に変更、`fetchHanchans()` 追加 |
| `flutter_app/lib/providers/hanchan_provider.dart` | 新規: HanchanNotifier |
| `flutter_app/lib/screens/hanchan/hanchan_screen.dart` | 新規: 半荘一覧画面 |
| `flutter_app/lib/screens/ranking/ranking_screen.dart` | AppBar に半荘一覧ボタン追加 |

---

## 7. 主要設定値

| 項目 | 値 |
|---|---|
| BigQuery プロジェクト (半荘データ) | `mahjonganalyzer` |
| BigQuery データセット (半荘データ) | `MM` |
| BigQuery テーブル | `J_HANCHANS_D` |
| BigQuery プロジェクト (kawai_cup) | `kaw-ai` |
| BigQuery データセット (kawai_cup) | `kawai_cup` |
| GAS スクリプト ID | `.clasp.json` 参照 |
| Firebase プロジェクト ID | `.firebaserc` 参照 |
