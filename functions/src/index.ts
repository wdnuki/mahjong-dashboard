import { onRequest } from 'firebase-functions/v2/https';
import express, { Request, Response } from 'express';
import cors from 'cors';
import {
  fetchRanking,
  fetchParticipants,
  fetchRelations,
  fetchHanchans,
  fetchParticipantHistory,
} from './bigquery';
import { sendSuccess, sendError, parseYear, parseMonth } from './utils';

const app = express();

// CORS: Firebase Hosting と同一ドメイン経由が推奨だが、直接アクセス時もブロックしない
app.use(cors({ origin: true }));

app.get('/', async (req: Request, res: Response) => {
  const params = req.query as Record<string, string>;
  const type = params['type'];
  const year = parseYear(params);
  const month = parseMonth(params);

  try {
    switch (type) {
      case 'ranking': {
        const data = await fetchRanking(year);
        sendSuccess(res, year, data);
        break;
      }
      case 'participants': {
        const data = await fetchParticipants(year);
        sendSuccess(res, year, data);
        break;
      }
      case 'relations': {
        const data = await fetchRelations(year);
        sendSuccess(res, year, data);
        break;
      }
      case 'hanchans': {
        const data = await fetchHanchans(year, month);
        sendSuccess(res, year, data);
        break;
      }
      case 'history': {
        const id = params['id'] ?? '';
        if (!id) {
          sendError(res, 'Missing parameter: id');
          break;
        }
        const data = await fetchParticipantHistory(id);
        sendSuccess(res, year, data);
        break;
      }
      default:
        sendError(
          res,
          `Unknown type: "${type ?? ''}". Use ranking, participants, relations, hanchans, or history.`
        );
    }
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Internal server error';
    console.error('API error:', err);
    sendError(res, message, 500);
  }
});

// Cloud Functions Gen2
export const api = onRequest(
  { region: 'us-central1', timeoutSeconds: 60, memory: '256MiB' },
  app
);
