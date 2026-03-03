/**
 * GAS Web App エントリポイント
 *
 * エンドポイント:
 *   ?type=ranking&year=2026          → ランキングデータ
 *   ?type=participants&year=2026     → 参加者一覧
 *   ?type=relations&year=2026        → 投票相関データ
 *   ?type=hanchans&year=2026&month=3 → 半荘一覧（年月指定）
 */

function doGet(
  e: GoogleAppsScript.Events.DoGet
): GoogleAppsScript.Content.TextOutput {
  try {
    const params = e.parameter as { [key: string]: string };
    const type = params['type'];
    const year = parseYear(params);
    const month = parseMonth(params);

    switch (type) {
      case 'ranking':
        return makeSuccessResponse(year, fetchRanking(year));

      case 'participants':
        return makeSuccessResponse(year, fetchParticipants(year));

      case 'relations':
        return makeSuccessResponse(year, fetchRelations(year));

      case 'hanchans':
        return makeSuccessResponse(year, fetchHanchans(year, month));

      case 'history': {
        const id = params['id'] || '';
        if (!id) return makeErrorResponse('Missing parameter: id');
        return makeSuccessResponse(year, fetchParticipantHistory(id));
      }

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
