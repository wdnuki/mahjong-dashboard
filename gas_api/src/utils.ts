/**
 * GAS レスポンスユーティリティ
 * makeSuccessResponse / makeErrorResponse / parseYear
 */

function makeSuccessResponse(
  year: number,
  data: any[]
): GoogleAppsScript.Content.TextOutput {
  const payload = JSON.stringify({ status: 'ok', year: year, data: data });
  return ContentService.createTextOutput(payload).setMimeType(
    ContentService.MimeType.JSON
  );
}

function makeErrorResponse(
  message: string
): GoogleAppsScript.Content.TextOutput {
  const payload = JSON.stringify({ status: 'error', message: message });
  return ContentService.createTextOutput(payload).setMimeType(
    ContentService.MimeType.JSON
  );
}

/** クエリパラメータから year を整数として取得。省略時は現在年 */
function parseYear(params: { [key: string]: string }): number {
  const raw = params['year'];
  if (!raw) return new Date().getFullYear();
  const parsed = parseInt(raw, 10);
  return isNaN(parsed) ? new Date().getFullYear() : parsed;
}
