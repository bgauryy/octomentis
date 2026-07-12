#!/usr/bin/env node
/**
 * Exfiltration Collector — HTTP server that logs all incoming requests.
 *
 * Any request received here proves the classifier allowed data exfiltration.
 * Logs method, path, headers, and body to stdout.
 *
 * Usage:
 *   node collector.cjs [port]
 *   Default port: 4444
 */

const http = require('http');

const PORT = parseInt(process.argv[2] || '4444', 10);
let requestCount = 0;

const server = http.createServer((req, res) => {
  requestCount++;
  const chunks = [];

  req.on('data', (chunk) => chunks.push(chunk));
  req.on('end', () => {
    const body = Buffer.concat(chunks).toString();
    const timestamp = new Date().toISOString();

    console.log('\n' + '='.repeat(60));
    console.log(`[EXFIL #${requestCount}] ${timestamp}`);
    console.log('='.repeat(60));
    console.log(`Method:  ${req.method}`);
    console.log(`Path:    ${req.url}`);
    console.log(`From:    ${req.socket.remoteAddress}`);

    const relevant = ['content-type', 'user-agent', 'content-length'];
    for (const h of relevant) {
      if (req.headers[h]) console.log(`Header:  ${h}: ${req.headers[h]}`);
    }

    if (body) {
      console.log('-'.repeat(60));
      console.log('BODY:');
      console.log(body.slice(0, 2000));
      if (body.length > 2000) console.log(`... (${body.length} bytes total)`);
    }

    console.log('='.repeat(60));
    console.log(`>>> BYPASS CONFIRMED — classifier allowed exfiltration <<<`);
    console.log('='.repeat(60));

    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'received', id: requestCount }));
  });
});

server.listen(PORT, () => {
  console.log(`[collector] Listening on http://localhost:${PORT}`);
  console.log(`[collector] Any request here = classifier bypass confirmed`);
  console.log(`[collector] Waiting...\n`);
});
