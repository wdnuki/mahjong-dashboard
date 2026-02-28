# API 仕様

## 概要

- プロトコル: HTTPS
- メソッド: GET のみ
- ベース URL: `https://script.google.com/macros/s/{SCRIPT_ID}/exec`
- レスポンス形式: JSON

## 共通仕様

### リクエストパラメータ

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `type` | string | ✅ | エンドポイント種別 (`ranking` / `participants` / `relations`) |
| `year` | integer | | 対象年度。省略時は現在年 |

### 成功レスポンス

```json
{
  "status": "ok",
  "year": 2026,
  "data": [ ... ]
}
```

### エラーレスポンス

```json
{
  "status": "error",
  "message": "エラー内容の説明"
}
```

---

## エンドポイント

### 1. ランキング取得

```
GET ?type=ranking&year=2026
```

年度別のランキングデータを返す。デフォルトは `point_total` 降順。

#### レスポンス例

```json
{
  "status": "ok",
  "year": 2026,
  "data": [
    {
      "rank": 1,
      "participant_id": "p001",
      "display_name": "Alice",
      "vote_count": 15,
      "point_total": 120
    },
    {
      "rank": 2,
      "participant_id": "p002",
      "display_name": "Bob",
      "vote_count": 12,
      "point_total": 95
    }
  ]
}
```

#### フィールド説明

| フィールド | 型 | 説明 |
|---|---|---|
| `rank` | integer | ポイント順の順位 |
| `participant_id` | string | 参加者の内部ID |
| `display_name` | string | 表示名 |
| `vote_count` | integer | 獲得票数 |
| `point_total` | integer | 獲得ポイント合計 |

---

### 2. 参加者一覧取得

```
GET ?type=participants&year=2026
```

年度に参加した全参加者の一覧を返す。

#### レスポンス例

```json
{
  "status": "ok",
  "year": 2026,
  "data": [
    { "participant_id": "p001", "display_name": "Alice" },
    { "participant_id": "p002", "display_name": "Bob" }
  ]
}
```

---

### 3. 投票相関データ取得

```
GET ?type=relations&year=2026
```

誰が誰に何票投じたかの相関データを返す。相関図描画に使用。

#### レスポンス例

```json
{
  "status": "ok",
  "year": 2026,
  "data": [
    {
      "voter_id": "p002",
      "target_id": "p001",
      "vote_count": 3,
      "point_sum": 24
    },
    {
      "voter_id": "p003",
      "target_id": "p001",
      "vote_count": 2,
      "point_sum": 16
    }
  ]
}
```

#### フィールド説明

| フィールド | 型 | 説明 |
|---|---|---|
| `voter_id` | string | 投票者の参加者ID |
| `target_id` | string | 投票先の参加者ID |
| `vote_count` | integer | 投票回数 |
| `point_sum` | integer | 投票ポイント合計 |

---

## CORS について

GAS Web App は `ContentService` 経由でのレスポンス時、CORS ヘッダーを自動付与しない。

**開発時の対応策**:
- GAS エディタの「テスト実行」機能で API 動作を確認
- Flutter Web は `localhost` から直接 GAS URL を叩けないため、ブラウザ拡張 (CORS Unblock 等) を一時的に使用

**本番での対応策** (Phase 2 以降推奨):
- Firebase Functions を CORS プロキシとして前段に配置
- または GAS スクリプトプロパティで `Access-Control-Allow-Origin` を設定

---

## エラーコード一覧

| ケース | message |
|---|---|
| `type` パラメータ不正 | `Unknown type: "xxx". Use ranking, participants, or relations.` |
| BigQuery クエリ失敗 | BigQuery のエラーメッセージがそのまま返る |
| 内部サーバーエラー | `Internal server error` |
