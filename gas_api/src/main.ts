/**
 * GAS Web App エントリポイント
 *
 * エンドポイント:
 *   ?type=ranking&year=2026     → ランキングデータ
 *   ?type=participants&year=2026 → 参加者一覧
 *   ?type=relations&year=2026   → 投票相関データ
 */

function doGet(
  e: GoogleAppsScript.Events.DoGet
): GoogleAppsScript.Content.TextOutput {
  try {
    const params = e.parameter as { [key: string]: string };
    const type = params['type'];
    const year = parseYear(params);

    switch (type) {
      case 'ranking':
        return makeSuccessResponse(year, fetchRanking(year));

      case 'participants':
        return makeSuccessResponse(year, fetchParticipants(year));

      case 'relations':
        return makeSuccessResponse(year, fetchRelations(year));

      default:
        return makeErrorResponse(
          `Unknown type: "${type}". Use ranking, participants, or relations.`
        );
    }
  } catch (err: any) {
    console.error('doGet error:', err);
    return makeErrorResponse(err.message || 'Internal server error');
  }
}
