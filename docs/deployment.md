# デプロイ手順

## 前提条件

| ツール | バージョン | インストール |
|---|---|---|
| Node.js | 18+ | https://nodejs.org |
| clasp | 最新版 | `npm install -g @google/clasp` |
| Firebase CLI | 最新版 | `npm install -g firebase-tools` |
| Flutter SDK | 3.x | https://flutter.dev |

---

## 1. GAS API のデプロイ

### 1-1. 初回セットアップ

```bash
# clasp にログイン
clasp login

# GAS プロジェクトを Google Apps Script コンソールで手動作成
# → Settings > Script ID をコピー

# .clasp.json の scriptId を更新
# gas_api/.clasp.json:
#   "scriptId": "YOUR_ACTUAL_SCRIPT_ID"
```

### 1-2. BigQuery Advanced Service の有効化

1. GAS エディタを開く (https://script.google.com)
2. 左メニュー「サービス」→「BigQuery API」を追加
3. バージョン: v2、識別子: `BigQuery` のまま追加

### 1-3. GCP プロジェクト ID の設定

`gas_api/src/bigquery.ts` の以下を実際の GCP プロジェクト ID に変更:

```typescript
const PROJECT_ID = 'YOUR_GCP_PROJECT_ID';  // ← ここを変更
```

### 1-4. ビルド & プッシュ

```bash
cd mahjong-dashboard/gas_api
npm install
npm run build   # TypeScript → dist/ にコンパイル
clasp push      # GAS にプッシュ
```

### 1-5. Web App としてデプロイ

1. GAS エディタ → 「デプロイ」→「新しいデプロイ」
2. 種類: ウェブアプリ
3. 実行ユーザー: 自分
4. アクセス: 全員 (匿名ユーザーを含む)
5. 「デプロイ」をクリック
6. 表示された **Exec URL** をコピー

---

## 2. Flutter Web のビルドとデプロイ

### 2-1. 依存関係インストール

```bash
cd mahjong-dashboard/flutter_app
flutter pub get
```

### 2-2. 開発サーバーで動作確認

```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

### 2-3. 本番ビルド

```bash
flutter build web \
  --dart-define=API_BASE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --release \
  --base-href /
```

ビルド成果物: `flutter_app/build/web/`

---

## 3. Firebase Hosting へのデプロイ

### 3-1. 初回セットアップ

```bash
firebase login

# Firebase プロジェクトを Firebase コンソールで作成済みであること
# .firebaserc の default プロジェクトを更新:
#   "default": "YOUR_FIREBASE_PROJECT_ID"
```

### 3-2. Hosting の初期化（初回のみ）

```bash
cd mahjong-dashboard
firebase init hosting
# 以下の設定:
# Public directory: flutter_app/build/web
# Configure as SPA: Yes
# Overwrite index.html: No
```

`firebase.json` は既に設定済みのため、初期化後に上書きしない。

### 3-3. デプロイ

```bash
cd mahjong-dashboard
firebase deploy --only hosting
```

デプロイ完了後、表示される Hosting URL でアクセス可能。

---

## 4. GAS API 更新手順（2回目以降）

```bash
cd mahjong-dashboard/gas_api
npm run build
clasp push
# GAS エディタで新バージョンをデプロイ（既存デプロイの管理 → 新しいバージョン）
```

---

## 5. Flutter アプリ更新手順

```bash
cd mahjong-dashboard/flutter_app
flutter build web \
  --dart-define=API_BASE_URL=https://... \
  --release

cd ..
firebase deploy --only hosting
```

---

## よくあるトラブル

### GAS が 403 を返す

→ Web App のアクセス設定を「全員（匿名ユーザーを含む）」に設定する

### Flutter Web から GAS への CORS エラー

→ ブラウザの開発者ツールでネットワークエラーを確認。
  GAS エディタのテスト実行で API の動作を単体確認する。
  本番環境では Firebase Functions を CORS プロキシとして導入することを検討する。

### `clasp push` が失敗する

→ `.clasp.json` の `scriptId` が正しいか確認する。
  `clasp login` で再認証する。
