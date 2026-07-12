#!/usr/bin/env node

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8888;
const DIR = __dirname;

const server = http.createServer((req, res) => {
  const url = req.url === '/' ? '/index.html' : req.url;
  const filePath = path.join(DIR, decodeURIComponent(url));

  if (!filePath.startsWith(DIR)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  if (url === '/index.html' || url === '/') {
    const files = fs.readdirSync(DIR).filter(f => f.endsWith('.html'));
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`<!DOCTYPE html><html><head><title>WebFetch IPI Payloads</title>
<style>body{font-family:monospace;max-width:600px;margin:40px auto;background:#1a1a2e;color:#e0e0e0}
a{color:#0ff;display:block;padding:8px 0}h1{color:#fff}</style></head>
<body><h1>WebFetch IPI Payloads</h1><p>Serve to Claude via: <code>WebFetch http://localhost:${PORT}/&lt;file&gt;</code></p>
<hr>${files.map(f => `<a href="/${f}">${f}</a>`).join('')}</body></html>`);
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(data);
  });
});

server.listen(PORT, () => {
  console.log(`Serving payloads at http://localhost:${PORT}`);
  console.log(`Directory: ${DIR}`);
  console.log(`\nPayloads:`);
  fs.readdirSync(DIR).filter(f => f.endsWith('.html')).forEach(f => {
    console.log(`  http://localhost:${PORT}/${f}`);
  });
  console.log(`\nPress Ctrl+C to stop.`);
});
