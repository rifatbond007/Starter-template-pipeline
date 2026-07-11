import express from 'express';
import { ok } from '@hackathon/shared';

const app = express();
const PORT = process.env.PORT ?? 8000;

app.get('/health', (_req, res) => {
  res.json(ok({ status: 'ok' }));
});

app.get('/api/status', (_req, res) => {
  res.json(ok({ app: 'server', version: process.env.APP_VERSION ?? 'unknown' }));
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default app;
