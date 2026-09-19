#!/usr/bin/env node
/**
 * Optional local dictionary proxy for Learn Mac.
 * GET /lookup?word=hello -> { "translation": "..." }
 *
 * Set ENJOY_API_TOKEN to proxy Enjoy /api/lookups (same as Enjoy desktop).
 */
import http from 'node:http';

const port = Number(process.env.PORT || 3847);
const enjoyBase = (process.env.ENJOY_API_BASE || 'https://enjoy.bot').replace(
  /\/+$/,
  '',
);
const enjoyToken = process.env.ENJOY_API_TOKEN || '';

const server = http.createServer(async (req, res) => {
  if (req.url?.startsWith('/lookup')) {
    const url = new URL(req.url, `http://127.0.0.1:${port}`);
    const word = url.searchParams.get('word')?.trim();
    if (!word) {
      res.writeHead(400);
      res.end(JSON.stringify({ error: 'missing word' }));
      return;
    }

    if (!enjoyToken) {
      res.writeHead(501);
      res.end(
        JSON.stringify({
          error: 'Set ENJOY_API_TOKEN to enable Enjoy dictionary proxy',
        }),
      );
      return;
    }

    try {
      const r = await fetch(`${enjoyBase}/api/lookups`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${enjoyToken}`,
        },
        body: JSON.stringify({
          word,
          context: word,
          native_language: 'zh-CN',
        }),
      });
      const body = await r.json();
      const translation =
        body?.meaning?.translation || body?.meaning?.definition || '';
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ translation }));
    } catch (err) {
      res.writeHead(502);
      res.end(JSON.stringify({ error: String(err) }));
    }
    return;
  }

  res.writeHead(404);
  res.end();
});

server.listen(port, () => {
  console.log(`dict sidecar on http://127.0.0.1:${port}/lookup?word=...`);
});
