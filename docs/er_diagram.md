# ER図 / データ構造ドキュメント

MongoDB (mahjongmanager) → BigQuery (MM データセット) のデータ構造を示す。

---

## MongoDB コレクション ER図

```
┌──────────────────────┐         ┌──────────────────────────┐
│      line_users      │         │          groups           │
├──────────────────────┤         ├──────────────────────────┤
│ _id (PK)             │         │ _id (PK)                  │
│ line_user_id ─────┐  │         │ line_group_id ──────┐     │
│ line_user_name    │  │         │ mode                │     │
│ mode              │  │         │ created_at          │     │
│ jantama_name      │  │         │ updated_at          │     │
│ original_id       │  │         └──────────┬──────────┘     │
│ created_at        │  │                    │1               │
│ updated_at        │  │         ┌──────────┴──────────┐     │
└──────┬────────────┘  │         │   group_settings    │     │
       │1              │         ├─────────────────────┤     │
       │               │         │ _id (PK)             │     │
  ┌────┴──────┐  ┌─────┴────┐   │ line_group_id (FK)   │     │
  │user_groups│  │  user_   │   │ rate                 │     │
  ├───────────┤  │ matches  │   │ ranking_prize[4]     │     │
  │ _id (PK)  │  ├──────────┤   │ tip_rate             │     │
  │line_user_ │  │ _id (PK) │   │ tobi_prize           │     │
  │  id (FK)  │  │ user_id  │   │ num_of_players       │     │
  │line_group_│  │  (FK→    │   │ rounding_method      │     │
  │  id (FK)  │  │users._id)│   └─────────────────────┘     │
  └───────────┘  │match_id  │                                 │
                 │  (FK)    │   ┌─────────────────────────┐  │
                 └────┬─────┘   │         matches          │  │
                      │N        ├─────────────────────────┤  │
                      │         │ _id (PK)                  │  │
                      │    1    │ line_group_id (FK) ────────┘  │
                      └────────►│ status                   │
                                │ active_hanchan_id (FK)   │
                                │ tip_scores   {map}       │
                                │ sum_scores   {map}       │
                                │ sum_prices   {map}       │
                                │ sum_prices_with_tip{map} │
                                │ tip_prices   {map}       │
                                │ original_id              │
                                │ created_at / updated_at  │
                                └──────────┬───────────────┘
                                           │1
                                    ┌──────┴───────────────┐
                                    │       hanchans        │
                                    ├───────────────────────┤
                                    │ _id (PK)               │
                                    │ match_id (FK)          │
                                    │ line_group_id (FK)     │
                                    │ raw_scores      {map}  │
                                    │ converted_scores{map}  │
                                    │ status                 │
                                    │ original_id            │
                                    │ created_at / updated_at│
                                    └──────────┬────────────┘
                                               │1
                                        ┌──────┴──────────┐
                                        │  user_hanchans  │
                                        ├─────────────────┤
                                        │ _id (PK)         │
                                        │ hanchan_id (FK)  │
                                        │ line_user_id(FK) │
                                        │ point            │
                                        │ rank             │
                                        │ yakuman_count    │
                                        │ created_at       │
                                        │ updated_at       │
                                        └─────────────────┘

┌──────────────────────────────────┐
│         command_aliases          │
├──────────────────────────────────┤
│ _id (PK)                          │
│ line_user_id (FK → line_users)    │
│ line_group_id (FK → groups)       │
│ alias                             │
│ command                           │
│ mentionees[]                      │
│ created_at / updated_at           │
└──────────────────────────────────┘
```

---

## コレクション一覧

| コレクション | 種別 | 説明 |
|---|---|---|
| `line_users` | マスター | LINEユーザー情報 |
| `groups` | マスター | LINEグループ情報 |
| `group_settings` | マスター | グループごとのレート・賞金設定（1:1） |
| `user_groups` | 中間 | ユーザー×グループの所属管理 |
| `matches` | トランザクション | 対局（複数半荘をまとめる単位）。スコア集計値をMap型で埋め込み保持 |
| `user_matches` | 中間 | ユーザー×対局の参加管理 |
| `hanchans` | トランザクション | 半荘（1ゲーム）。素点・変換スコアをMap型 `{lineUserId: 数値}` で埋め込み |
| `user_hanchans` | 中間 | ユーザー×半荘の正規化テーブル（hanchansのMap型を展開した形） |
| `command_aliases` | 設定 | グループ・ユーザーごとのコマンドエイリアス設定 |

---

## BigQuery テーブル ER図（データセット: MM）

MongoDB から BigQuery への取り込み構造。

```
┌──────────────────────────┐
│       M_LINE_USERS        │
├──────────────────────────┤
│ LINE_USER_ID (PK) ─────┐  │  ← MongoDB: line_users
│ LINE_USER_NAME         │  │
│ CREATED_AT             │  │
│ UPDATED_AT             │  │
│ IMPORTED_AT            │  │
└────────────────────────┘  │
                            │1
              ┌─────────────┼─────────────────┐
              │N            │N                │N
┌─────────────┴──┐  ┌───────┴────────┐  ┌────┴────────────────┐
│  J_HANCHANS_D  │  │ J_HANCHANS_H   │  │  J_USER_HANCHANS_D  │
├────────────────┤  ├────────────────┤  ├─────────────────────┤
│ HANCHAN_ID(FK) │  │ HANCHAN_ID(PK) │  │ LINE_USER_ID (FK)    │
│ LINE_USER_ID   │  │ MATCH_ID       │  │ HANCHAN_ID (FK)      │
│   (FK)         │  │  (→matches未取込)│  │ RANK                 │
│ SOTEN          │  │ KANRI_DATE     │  │ CREATED_AT           │
│ POINT          │  │ CREATED_AT     │  │ UPDATED_AT           │
│ POINT_ZONE     │  │ UPDATED_AT     │  │ IMPORTED_AT          │
│ RANK           │  │ IMPORTED_AT    │  └─────────────────────┘
│ CREATED_AT     │  └────────────────┘
│ UPDATED_AT     │    ← MongoDB: hanchans（ヘッダー部分）
│ IMPORTED_AT    │
└────────────────┘
  ← MongoDB: hanchans.raw_scores / converted_scores を
    プレイヤー数分に展開（1ドキュメント → N行）
```

### BigQuery テーブル定義

#### M_LINE_USERS（マスター: LINEユーザー）

| カラム | 型 | 説明 |
|---|---|---|
| `LINE_USER_ID` | STRING | LINE ユーザーID（PK） |
| `LINE_USER_NAME` | STRING | 表示名 |
| `CREATED_AT` | DATETIME | 作成日時（JST） |
| `UPDATED_AT` | DATETIME | 更新日時（JST） |
| `IMPORTED_AT` | DATETIME | BQ取込日時（JST） |

#### J_HANCHANS_H（半荘ヘッダー）

| カラム | 型 | 説明 |
|---|---|---|
| `HANCHAN_ID` | STRING | 半荘ID（PK、MongoDB ObjectId） |
| `MATCH_ID` | STRING | 対局ID（FK、未取込） |
| `KANRI_DATE` | DATE | 管理日付（updated_at基準、12時前は前日） |
| `CREATED_AT` | DATETIME | 作成日時（JST） |
| `UPDATED_AT` | DATETIME | 更新日時（JST） |
| `IMPORTED_AT` | DATETIME | BQ取込日時（JST） |

#### J_HANCHANS_D（半荘詳細スコア）

| カラム | 型 | 説明 |
|---|---|---|
| `HANCHAN_ID` | STRING | 半荘ID（FK → J_HANCHANS_H） |
| `LINE_USER_ID` | STRING | LINE ユーザーID（FK → M_LINE_USERS） |
| `SOTEN` | NUMERIC | 素点 |
| `POINT` | NUMERIC | ポイント（変換後） |
| `POINT_ZONE` | NUMERIC | ポイント域（10点単位） |
| `RANK` | NUMERIC | 順位（1〜4） |
| `CREATED_AT` | DATETIME | 作成日時（JST） |
| `UPDATED_AT` | DATETIME | 更新日時（JST） |
| `IMPORTED_AT` | DATETIME | BQ取込日時（JST） |

#### J_USER_HANCHANS_D（ユーザー×半荘）

| カラム | 型 | 説明 |
|---|---|---|
| `LINE_USER_ID` | STRING | LINE ユーザーID（FK → M_LINE_USERS） |
| `HANCHAN_ID` | STRING | 半荘ID（FK → J_HANCHANS_H） |
| `RANK` | NUMERIC | 順位 |
| `CREATED_AT` | DATETIME | 作成日時（JST） |
| `UPDATED_AT` | DATETIME | 更新日時（JST） |
| `IMPORTED_AT` | DATETIME | BQ取込日時（JST） |

---

## 備考

- `J_HANCHANS_D` と `J_USER_HANCHANS_D` は HANCHAN_ID × LINE_USER_ID × RANK を重複保持している（MongoDB側で `hanchans` と `user_hanchans` が別コレクションのため）
- `MATCH_ID` が参照する `matches` コレクションは現時点で BigQuery 未取込
- `KANRI_DATE` は `updated_at` が12時前の場合は前日扱い（深夜帯の卓を前日として集計するため）
