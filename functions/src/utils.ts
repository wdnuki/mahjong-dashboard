import type { Response } from 'express';

/** JSON 成功レスポンスを送信する */
export function sendSuccess(res: Response, year: number, data: unknown[]): void {
  res.json({ status: 'ok', year, data });
}

/** JSON エラーレスポンスを送信する */
export function sendError(res: Response, message: string, statusCode = 400): void {
  res.status(statusCode).json({ status: 'error', message });
}

/** year クエリパラメータをパースする。未指定時は現在年 */
export function parseYear(params: Record<string, string>): number {
  const raw = params['year'];
  if (!raw) return new Date().getFullYear();
  const parsed = parseInt(raw, 10);
  return isNaN(parsed) ? new Date().getFullYear() : parsed;
}

/** month クエリパラメータをパースする (1-12)。未指定時は現在月 */
export function parseMonth(params: Record<string, string>): number {
  const raw = params['month'];
  if (!raw) return new Date().getMonth() + 1;
  const parsed = parseInt(raw, 10);
  return isNaN(parsed) || parsed < 1 || parsed > 12
    ? new Date().getMonth() + 1
    : parsed;
}
