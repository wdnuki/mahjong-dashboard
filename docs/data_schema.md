# データスキーマ

## BigQuery データセット

- **プロジェクト**: `YOUR_GCP_PROJECT_ID`
- **データセット**: `kawai_cup`

---

## テーブル定義

### kawai_votes（投票データ）

| カラム | 型 | 説明 |
|---|---|---|
| `event_year` | INTEGER | イベント開催年 (例: 2026) |
| `voter_id` | STRING | 投票者の参加者ID |
| `target_id` | STRING | 投票先の参加者ID |
| `vote_point` | INTEGER | この投票で付与したポイント |
| `target_point` | INTEGER | 投票時点での投票先の累計ポイント |
| `timestamp` | TIMESTAMP | 投票日時 (UTC) |

**DDL**

```sql
CREATE TABLE `YOUR_GCP_PROJECT_ID.kawai_cup.kawai_votes` (
  event_year    INT64     NOT NULL,
  voter_id      STRING    NOT NULL,
  target_id     STRING    NOT NULL,
  vote_point    INT64     NOT NULL,
  target_point  INT64,
  timestamp     TIMESTAMP NOT NULL
);
```

---

### kawai_participants（参加者マスタ）

| カラム | 型 | 説明 |
|---|---|---|
| `event_year` | INTEGER | イベント開催年 |
| `participant_id` | STRING | 参加者の一意ID |
| `display_name` | STRING | ダッシュボードに表示する名前 |

**DDL**

```sql
CREATE TABLE `YOUR_GCP_PROJECT_ID.kawai_cup.kawai_participants` (
  event_year      INT64  NOT NULL,
  participant_id  STRING NOT NULL,
  display_name    STRING NOT NULL
);
```

---

## 想定データ量

| テーブル | 想定行数 |
|---|---|
| kawai_participants | 年10〜20人 × 年数 |
| kawai_votes | 年1000件以下 |

BigQuery の無料枠（月1TB クエリ、10GB ストレージ）で十分に収まる。

---

## 主要クエリ

### ランキング集計

```sql
SELECT
  p.participant_id,
  p.display_name,
  COALESCE(COUNT(v.voter_id), 0) AS vote_count,
  COALESCE(SUM(v.vote_point), 0) AS point_total
FROM `YOUR_GCP_PROJECT_ID.kawai_cup.kawai_participants` p
LEFT JOIN `YOUR_GCP_PROJECT_ID.kawai_cup.kawai_votes` v
  ON p.participant_id = v.target_id
  AND p.event_year = v.event_year
WHERE p.event_year = @year
GROUP BY p.participant_id, p.display_name
ORDER BY point_total DESC
```

### 投票相関集計

```sql
SELECT
  voter_id,
  target_id,
  COUNT(*) AS vote_count,
  SUM(vote_point) AS point_sum
FROM `YOUR_GCP_PROJECT_ID.kawai_cup.kawai_votes`
WHERE event_year = @year
GROUP BY voter_id, target_id
ORDER BY voter_id, point_sum DESC
```

### 参加者一覧

```sql
SELECT participant_id, display_name
FROM `YOUR_GCP_PROJECT_ID.kawai_cup.kawai_participants`
WHERE event_year = @year
ORDER BY participant_id
```

---

## データ投入方法

管理者が BigQuery コンソール または `bq` CLI で手動投入する。

```bash
# 参加者を追加する例
bq query --use_legacy_sql=false '
  INSERT INTO `YOUR_GCP_PROJECT_ID.kawai_cup.kawai_participants`
  VALUES (2026, "p001", "Alice")
'

# 投票を追加する例
bq query --use_legacy_sql=false '
  INSERT INTO `YOUR_GCP_PROJECT_ID.kawai_cup.kawai_votes`
  VALUES (2026, "p002", "p001", 10, 10, CURRENT_TIMESTAMP())
'
```

---

## 年度追加時の対応

`kawai_participants` に新しい `event_year` のレコードを追加するだけで対応完了。
コードの変更は不要。`YearNotifier.availableYears` は動的に現在年まで生成する。
