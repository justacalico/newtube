import http from 'node:http';
import { Readable } from 'node:stream';

const port = Number(process.env.PORT || 8090);

const server = http.createServer(async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', '*');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Access-Control-Expose-Headers', '*');
  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }
  const params = new URL(req.url, `http://localhost:${port}`).searchParams;
  const target = params.get('u') ?? params.get('url');
  if (!target) {
    res.writeHead(400);
    res.end('missing url param');
    return;
  }
  try {
    const headers = {};
    for (const h of ['content-type', 'user-agent', 'accept', 'range']) {
      const v = req.headers[h];
      if (v) headers[h] = v;
    }
    const body =
      req.method === 'GET' || req.method === 'HEAD'
        ? undefined
        : Buffer.concat(await Array.fromAsync(req));
    const upstream = await fetch(target, {
      method: req.method,
      headers,
      body,
      redirect: 'follow',
    });
    const out = {
      'Access-Control-Allow-Origin': '*',
    };
    for (const h of [
      'content-type',
      'content-range',
      'accept-ranges',
      'etag',
      'last-modified',
    ]) {
      const v = upstream.headers.get(h);
      if (v) out[h] = v;
    }
    if (!upstream.headers.get('content-encoding')) {
      const len = upstream.headers.get('content-length');
      if (len) out['content-length'] = len;
    }
    res.writeHead(upstream.status, out);
    if (req.method === 'HEAD' || !upstream.body) {
      res.end();
      return;
    }
    Readable.fromWeb(upstream.body).pipe(res);
  } catch (e) {
    res.writeHead(502);
    res.end(String(e));
  }
});

server.listen(port, () => console.log(`cors proxy on :${port}`));
