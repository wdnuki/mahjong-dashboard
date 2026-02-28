# アーキテクチャ

## システム全体図

```
┌─────────────────────────────────────────┐
│  ユーザー (ブラウザ / スマホ)            │
└──────────────┬──────────────────────────┘
               │ HTTPS
┌──────────────▼──────────────────────────┐
│  Firebase Hosting                        │
│  Flutter Web SPA                         │
│  (flutter_app/build/web)                 │
└──────────────┬──────────────────────────┘
               │ HTTP GET ?type=...&year=...
┌──────────────▼──────────────────────────┐
│  Google Apps Script (Web App)            │
│  doGet(e) → BigQuery API                 │
└──────────────┬──────────────────────────┘
               │ BigQuery Jobs.query()
┌──────────────▼──────────────────────────┐
│  BigQuery                                │
│  dataset: kawai_cup                      │
│  - kawai_votes                           │
│  - kawai_participants                    │
└─────────────────────────────────────────┘
```

## データフロー

1. ユーザーが Flutter Web アプリを開く
2. Flutter が GAS Web App に HTTP GET リクエストを送信
   - クエリパラメータ: `type`, `year`
3. GAS が BigQuery に SQL クエリを実行
4. BigQuery が結果を返却
5. GAS が JSON 形式でレスポンスを返却
6. Flutter が JSON をパースしてUI を描画

## Flutter アプリ層構造

```
flutter_app/lib/
├── main.dart                      # エントリポイント / API_BASE_URL ログ
├── app/
│   └── app.dart                   # MaterialApp / テーマ / ルーティング
├── models/
│   ├── ranking_entry.dart         # ランキング1行のデータモデル
│   ├── participant.dart           # 参加者データモデル
│   └── relation.dart              # 投票相関データモデル
├── services/
│   └── api_service.dart           # HTTP通信 / API_BASE_URL 読み取り
├── providers/
│   ├── year_provider.dart         # 選択年の状態管理 (ChangeNotifier)
│   └── ranking_provider.dart      # ランキングデータ + ソート状態管理
├── widgets/
│   ├── year_selector.dart         # 年選択ドロップダウン
│   ├── loading_indicator.dart     # ローディング表示
│   └── ranking_bar_chart.dart     # fl_chart 棒グラフ (トップ10)
└── screens/ranking/
    ├── ranking_screen.dart        # ランキング画面 (StatefulWidget)
    └── ranking_table.dart         # DataTable + ソート
```

## GAS API 層構造

```
gas_api/src/
├── utils.ts       # makeSuccessResponse / makeErrorResponse / parseYear
├── bigquery.ts    # fetchRanking / fetchParticipants / fetchRelations / runQuery
└── main.ts        # doGet(e) — type パラメータでルーティング
```

**注意**: GAS はファイルをグローバルスコープに連結するため `import`/`export` は不使用。
`tsconfig.json` で各ファイルを `dist/` にコンパイルし、clasp が GAS にプッシュする。

## 技術選定理由

| 技術 | 理由 |
|---|---|
| Flutter Web | Dart単言語でクロスプラットフォーム。fl_chart で高品質なグラフ |
| GAS | BigQuery への直接アクセス。サーバー不要。Google環境で完結 |
| BigQuery | Google環境の標準データウェアハウス。SQLで柔軟な集計 |
| Firebase Hosting | 無料枠で静的SPA配信。Flutter Webと相性良好 |
| clasp + TypeScript | GASをローカル開発。型安全性の確保 |

## 将来の Cloud Functions 移行パス

現在 GAS が担う API 層を Cloud Functions (Node.js) に移行することで:
- CORS 問題を解消（GAS の制限を回避）
- より複雑なビジネスロジックの実装が可能
- スケーラビリティの向上

`ApiService` の `_baseUrl` を切り替えるだけで移行可能な設計になっている。
