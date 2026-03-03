// @google-cloud/bigquery の import はモジュールレベルに置かない。
// require() を初回リクエスト時に遅延実行することで、Firebase CLI の
// コード分析タイムアウト (10秒) を回避する。
import type { BigQuery as BigQueryType } from '@google-cloud/bigquery';

const PROJECT_ID = 'mahjonganalyzer';
const DATASET = 'kawai_cup';
const MM_PROJECT_ID = 'mahjonganalyzer';
const DATASET_MM = 'MM';

let _bq: BigQueryType | null = null;

function getBQ(): BigQueryType {
  if (!_bq) {
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const { BigQuery } = require('@google-cloud/bigquery');
    _bq = new BigQuery({ projectId: PROJECT_ID });
  }
  return _bq!;
}

/** BigQuery クエリを実行して行の配列を返す */
async function runQuery<T extends Record<string, unknown>>(sql: string): Promise<T[]> {
  return new Promise((resolve, reject) => {
    getBQ().query(
      { query: sql, useLegacySql: false, jobTimeoutMs: 30000 },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (err: Error | null, rows?: any[] | null) => {
        if (err) { reject(err); return; }
        resolve((rows ?? []) as T[]);
      }
    );
  });
}

/** ランキングデータを取得する (point_total 降順) */
export async function fetchRanking(year: number): Promise<unknown[]> {
  const sql = `
    SELECT
      p.participant_id,
      p.display_name,
      COALESCE(COUNT(v.voter_id), 0) AS vote_count,
      COALESCE(SUM(v.vote_point), 0) AS point_total
    FROM \`${PROJECT_ID}.${DATASET}.kawai_participants\` p
    LEFT JOIN \`${PROJECT_ID}.${DATASET}.kawai_votes\` v
      ON p.participant_id = v.target_id
      AND p.event_year = v.event_year
    WHERE p.event_year = ${year}
    GROUP BY p.participant_id, p.display_name
    ORDER BY point_total DESC
  `;

  type Row = { participant_id: string; display_name: string; vote_count: unknown; point_total: unknown };
  const rows = await runQuery<Row>(sql);
  return rows.map((row, index) => ({
    rank: index + 1,
    participant_id: row.participant_id,
    display_name: row.display_name,
    vote_count: Number(row.vote_count ?? 0),
    point_total: Number(row.point_total ?? 0),
  }));
}

/** 参加者一覧を取得する */
export async function fetchParticipants(year: number): Promise<unknown[]> {
  const sql = `
    SELECT participant_id, display_name
    FROM \`${PROJECT_ID}.${DATASET}.kawai_participants\`
    WHERE event_year = ${year}
    ORDER BY participant_id
  `;

  type Row = { participant_id: string; display_name: string };
  const rows = await runQuery<Row>(sql);
  return rows.map((row) => ({
    participant_id: row.participant_id,
    display_name: row.display_name,
  }));
}

/** 投票者→対象者の相関データを取得する */
export async function fetchRelations(year: number): Promise<unknown[]> {
  const sql = `
    SELECT
      voter_id,
      target_id,
      COUNT(*) AS vote_count,
      SUM(vote_point) AS point_sum
    FROM \`${PROJECT_ID}.${DATASET}.kawai_votes\`
    WHERE event_year = ${year}
    GROUP BY voter_id, target_id
    ORDER BY voter_id, point_sum DESC
  `;

  type Row = { voter_id: string; target_id: string; vote_count: unknown; point_sum: unknown };
  const rows = await runQuery<Row>(sql);
  return rows.map((row) => ({
    voter_id: row.voter_id,
    target_id: row.target_id,
    vote_count: Number(row.vote_count ?? 0),
    point_sum: Number(row.point_sum ?? 0),
  }));
}

/** 半荘データ一覧を取得する（年月フィルター対応） */
export async function fetchHanchans(year: number, month: number): Promise<unknown[]> {
  const sql = `
    SELECT
      HANCHAN_ID,
      KANRI_DATE,
      LINE_USER_ID,
      NICK_NAME,
      LINE_USER_NAME,
      SOTEN,
      POINT,
      RANK,
      DEAD_FLAG,
      KILL_CNT
    FROM \`${MM_PROJECT_ID}.${DATASET_MM}.V_HANCHANS\`
    WHERE
      KANRI_DATE >= DATE(${year}, ${month}, 1)
      AND KANRI_DATE < DATE_ADD(DATE(${year}, ${month}, 1), INTERVAL 1 MONTH)
    ORDER BY HANCHAN_ID DESC, RANK ASC
  `;

  type Row = {
    HANCHAN_ID: string;
    KANRI_DATE: { value: string } | string;
    LINE_USER_ID: string;
    NICK_NAME: string;
    LINE_USER_NAME: string;
    SOTEN: unknown;
    POINT: unknown;
    RANK: unknown;
    DEAD_FLAG: string;
    KILL_CNT: unknown;
  };
  const rows = await runQuery<Row>(sql);
  return rows.map((row) => ({
    hanchan_id: row.HANCHAN_ID,
    kanri_date:
      typeof row.KANRI_DATE === 'object' && row.KANRI_DATE !== null
        ? (row.KANRI_DATE as { value: string }).value
        : String(row.KANRI_DATE ?? ''),
    line_user_id: row.LINE_USER_ID,
    nick_name: row.NICK_NAME ?? '',
    line_user_name: row.LINE_USER_NAME ?? '',
    soten: parseFloat(String(row.SOTEN ?? 0)),
    point: parseFloat(String(row.POINT ?? 0)),
    rank: parseInt(String(row.RANK ?? 0), 10),
    dead_flag: row.DEAD_FLAG ?? '',
    kill_cnt: parseInt(String(row.KILL_CNT ?? 0), 10),
  }));
}

/** 参加者の年度別履歴データを取得する */
export async function fetchParticipantHistory(participantId: string): Promise<unknown[]> {
  const safeId = participantId.replace(/'/g, "''");
  const sql = `
    SELECT
      p.event_year,
      p.display_name,
      COALESCE(COUNT(v.voter_id), 0) AS vote_count,
      COALESCE(SUM(v.vote_point), 0) AS point_total
    FROM \`${PROJECT_ID}.${DATASET}.kawai_participants\` p
    LEFT JOIN \`${PROJECT_ID}.${DATASET}.kawai_votes\` v
      ON p.participant_id = v.target_id
      AND p.event_year = v.event_year
    WHERE p.participant_id = '${safeId}'
    GROUP BY p.event_year, p.display_name
    ORDER BY p.event_year ASC
  `;

  type Row = { event_year: unknown; display_name: string; vote_count: unknown; point_total: unknown };
  const rows = await runQuery<Row>(sql);
  return rows.map((row) => ({
    event_year: parseInt(String(row.event_year ?? 0), 10),
    display_name: row.display_name ?? '',
    vote_count: Number(row.vote_count ?? 0),
    point_total: Number(row.point_total ?? 0),
  }));
}
