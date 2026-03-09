import express from 'express';
import { env } from './env';

const app = express();

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', service: 'api', environment: env.NODE_ENV });
});

app.listen(env.PORT, () => {
  console.log(`API listening on http://localhost:${env.PORT}`);
});
