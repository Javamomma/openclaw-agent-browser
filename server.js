#!/usr/bin/env node
'use strict';

const http = require('node:http');

const BRIDGE_PORT = 18793;
const BRIDGE_HOST = '127.0.0.1';
const CHROME_PORT = 9222;
const CHROME_HOST = '127.0.0.1';

// Strip headers that trigger Chrome's CDP origin checks
function safeHeaders(headers) {
  const safe = {};
  for (const [k, v] of Object.entries(headers)) {
    const lower = k.toLowerCase();
    if (lower === 'host' || lower === 'origin' || lower === 'referer') continue;
    safe[k] = v;
  }
  safe.host = `${CHROME_HOST}:${CHROME_PORT}`;
  return safe;
}

// ---- HTTP proxy ----
// Forwards /json/* requests to Chrome's CDP HTTP API
// Rewrites webSocketDebuggerUrl from :9222 to :18792

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    const check = http.get(
      `http://${CHROME_HOST}:${CHROME_PORT}/json/version`,
      (proxyRes) => {
        let body = '';
        proxyRes.on('data', (d) => (body += d));
        proxyRes.on('end', () => {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ ok: true, chrome: JSON.parse(body) }));
        });
      }
    );
    check.on('error', (err) => {
      res.writeHead(503, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ ok: false, error: err.message }));
    });
    return;
  }

  const proxyReq = http.request(
    {
      hostname: CHROME_HOST,
      port: CHROME_PORT,
      path: req.url,
      method: req.method,
      headers: safeHeaders(req.headers),
    },
    (proxyRes) => {
      let body = '';
      proxyRes.on('data', (d) => (body += d));
      proxyRes.on('end', () => {
        // Rewrite all CDP URLs from Chrome's port to the bridge port
        const rewritten = body.replaceAll(
          `${CHROME_HOST}:${CHROME_PORT}`,
          `${BRIDGE_HOST}:${BRIDGE_PORT}`
        );
        const headers = { ...proxyRes.headers };
        if (headers['content-length']) {
          headers['content-length'] = Buffer.byteLength(rewritten);
        }
        res.writeHead(proxyRes.statusCode, headers);
        res.end(rewritten);
      });
    }
  );

  proxyReq.on('error', (err) => {
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: `Chrome CDP not available: ${err.message}` }));
  });

  req.pipe(proxyReq);
});

// ---- WebSocket proxy ----
// Transparent bidirectional pipe between client and Chrome's CDP WebSocket

server.on('upgrade', (req, clientSocket, head) => {
  console.log(`WS connect: ${req.url}`);

  const proxyReq = http.request({
    hostname: CHROME_HOST,
    port: CHROME_PORT,
    path: req.url,
    method: 'GET',
    headers: safeHeaders(req.headers),
  });

  proxyReq.on('upgrade', (proxyRes, chromeSocket, proxyHead) => {
    // Forward Chrome's 101 Switching Protocols response to the client
    let response = `HTTP/${proxyRes.httpVersion} ${proxyRes.statusCode} ${proxyRes.statusMessage}\r\n`;
    for (let i = 0; i < proxyRes.rawHeaders.length; i += 2) {
      response += `${proxyRes.rawHeaders[i]}: ${proxyRes.rawHeaders[i + 1]}\r\n`;
    }
    response += '\r\n';

    clientSocket.write(response);
    if (proxyHead.length) clientSocket.write(proxyHead);
    if (head.length) chromeSocket.write(head);

    // Bidirectional pipe — raw TCP, no frame parsing
    clientSocket.pipe(chromeSocket);
    chromeSocket.pipe(clientSocket);

    clientSocket.on('error', () => chromeSocket.destroy());
    chromeSocket.on('error', () => clientSocket.destroy());
    clientSocket.on('close', () => {
      console.log(`WS closed: ${req.url}`);
      chromeSocket.destroy();
    });
    chromeSocket.on('close', () => clientSocket.destroy());
  });

  proxyReq.on('error', (err) => {
    console.error(`WS error: ${req.url} — ${err.message}`);
    clientSocket.write('HTTP/1.1 502 Bad Gateway\r\n\r\n');
    clientSocket.destroy();
  });

  proxyReq.end();
});

// ---- Start ----

server.listen(BRIDGE_PORT, BRIDGE_HOST, () => {
  console.log(`CDP Bridge listening on http://${BRIDGE_HOST}:${BRIDGE_PORT}`);
  console.log(`Proxying to Chrome CDP at http://${CHROME_HOST}:${CHROME_PORT}`);
});

process.on('SIGINT', () => process.exit(0));
process.on('SIGTERM', () => process.exit(0));
