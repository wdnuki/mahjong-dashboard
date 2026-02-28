# mahjong-dashboard

カワイカップ（イベント投票）のランキングを可視化するダッシュボード。

## アーキテクチャ

```
Flutter Web (Firebase Hosting)
    ↓ HTTP GET
GAS Web App (Google Apps Script)
    ↓ BigQuery API
BigQuery (kawai_votes, kawai_participants)
```

## ディレクトリ構成

```
mahjong-dashboard/
├── flutter_app/    # Flutter Web フロントエンド
├── gas_api/        # GAS API (clasp + TypeScript)
├── docs/           # 設計書・仕様書
├── firebase.json   # Firebase Hosting 設定
└── .firebaserc     # Firebase プロジェクト設定
```

## クイックスタート

### GAS API のデプロイ

```bash
cd gas_api
npm install
# clasp login & GASプロジェクト作成後:
npm run build
clasp push
# GAS エディタで Web App としてデプロイ → exec URL を控える
```

### Flutter Web の起動（開発）

```bash
cd flutter_app
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

### Flutter Web のビルド（本番）

```bash
cd flutter_app
flutter build web \
  --dart-define=API_BASE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --base-href /
```

### Firebase Hosting へのデプロイ

```bash
firebase login
firebase deploy --only hosting
```

## 環境変数

| 変数名 | 説明 | 渡し方 |
|---|---|---|
| `API_BASE_URL` | GAS Web App の exec URL | `--dart-define` |

## 設定が必要なプレースホルダー

| ファイル | 変更箇所 |
|---|---|
| `gas_api/.clasp.json` | `YOUR_SCRIPT_ID_HERE` |
| `gas_api/src/bigquery.ts` | `YOUR_GCP_PROJECT_ID` |
| `.firebaserc` | `YOUR_FIREBASE_PROJECT_ID` |

## 開発フェーズ

- **Phase 1** (現在): ランキング表示、年度切替、ソート
- **Phase 2**: 個人詳細ページ、年度別推移
- **Phase 3**: 投票相関図

## 関連ドキュメント

- [アーキテクチャ](docs/architecture.md)
- [API仕様](docs/api_spec.md)
- [データスキーマ](docs/data_schema.md)
- [デプロイ手順](docs/deployment.md)
