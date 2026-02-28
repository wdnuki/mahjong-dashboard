/**
 * BigQuery クエリ関数群
 * BigQuery Advanced Service (GAS) を使用する
 *
 * PROJECT_ID と DATASET を実際の値に変更すること
 */

const PROJECT_ID = 'YOUR_GCP_PROJECT_ID';
const DATASET = 'kawai_cup';

/** ランキングデータを取得する (point_total 降順) */
function fetchRanking(year: number): any[] {
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

  const rows = runQuery(sql);
  return rows.map((row: any[], index: number) => ({
    rank: index + 1,
    participant_id: row[0],
    display_name: row[1],
    vote_count: parseInt(row[2] || '0', 10),
    point_total: parseInt(row[3] || '0', 10),
  }));
}

/** 参加者一覧を取得する */
function fetchParticipants(year: number): any[] {
  const sql = `
    SELECT participant_id, display_name
    FROM \`${PROJECT_ID}.${DATASET}.kawai_participants\`
    WHERE event_year = ${year}
    ORDER BY participant_id
  `;

  const rows = runQuery(sql);
  return rows.map((row: any[]) => ({
    participant_id: row[0],
    display_name: row[1],
  }));
}

/** 投票者→対象者の相関データを取得する */
function fetchRelations(year: number): any[] {
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

  const rows = runQuery(sql);
  return rows.map((row: any[]) => ({
    voter_id: row[0],
    target_id: row[1],
    vote_count: parseInt(row[2] || '0', 10),
    point_sum: parseInt(row[3] || '0', 10),
  }));
}

/**
 * BigQuery 同期クエリ実行のラッパー
 * rows が null の場合は空配列を返す
 */
function runQuery(sql: string): any[][] {
  const request = {
    query: sql,
    useLegacySql: false,
    timeoutMs: 30000,
  };

  const response = BigQuery.Jobs!.query(request, PROJECT_ID);
  if (!response.rows) return [];

  return response.rows.map((row: any) =>
    row.f.map((field: any) => field.v)
  );
}
