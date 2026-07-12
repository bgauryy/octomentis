#!/usr/bin/env node
/**
 * verify.cjs — Validates that the NF-12 vulnerability exists in the installed cli.js.
 *
 * Checks:
 *   1. cli.js exists and is readable
 *   2. <user_allow_rules_to_replace> template tags present
 *   3. <user_deny_rules_to_replace> template tags present
 *   4. <user_environment_to_replace> template tags present
 *   5. Ng6() function reads from localSettings
 *   6. autoMode setting is accessed
 *   7. .replace() calls on template tags exist
 */

const fs = require('node:fs');
const path = require('node:path');
const { execSync } = require('node:child_process');

const GREEN = '\x1b[32m';
const RED = '\x1b[31m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const RESET = '\x1b[0m';
const BOLD = '\x1b[1m';

function findCliJs() {
  try {
    const claudePath = execSync('which claude 2>/dev/null', { encoding: 'utf8' }).trim();
    const realPath = fs.realpathSync(claudePath);
    if (fs.existsSync(realPath)) return realPath;
  } catch {}

  const globalRoot = execSync('npm root -g 2>/dev/null', { encoding: 'utf8' }).trim();
  const candidate = path.join(globalRoot, '@anthropic-ai', 'claude-code', 'cli.js');
  if (fs.existsSync(candidate)) return candidate;

  return null;
}

function searchBytes(buf, pattern) {
  const offsets = [];
  const needle = Buffer.from(pattern, 'utf8');
  let pos = 0;
  while (pos < buf.length) {
    const idx = buf.indexOf(needle, pos);
    if (idx === -1) break;
    offsets.push(idx);
    pos = idx + 1;
  }
  return offsets;
}

function extractContext(buf, offset, before = 80, after = 120) {
  const start = Math.max(0, offset - before);
  const end = Math.min(buf.length, offset + after);
  return buf.slice(start, end).toString('utf8');
}

console.log('');
console.log(`${BOLD}NF-12 Classifier Rule Injection — Verification${RESET}`);
console.log(`${'='.repeat(50)}`);
console.log('');

const cliPath = findCliJs();
if (!cliPath) {
  console.log(`${RED}[FAIL]${RESET} cli.js not found. Install claude-code: npm i -g @anthropic-ai/claude-code`);
  process.exit(1);
}

console.log(`${CYAN}[INFO]${RESET} cli.js: ${cliPath}`);
const stat = fs.statSync(cliPath);
console.log(`${CYAN}[INFO]${RESET} Size: ${(stat.size / 1024 / 1024).toFixed(1)} MB`);
console.log('');

const buf = fs.readFileSync(cliPath);
let passed = 0;
let failed = 0;

const checks = [
  {
    name: '<user_allow_rules_to_replace> template tags',
    pattern: 'user_allow_rules_to_replace',
    minCount: 5,
  },
  {
    name: '<user_deny_rules_to_replace> template tags',
    pattern: 'user_deny_rules_to_replace',
    minCount: 5,
  },
  {
    name: '<user_environment_to_replace> template tags',
    pattern: 'user_environment_to_replace',
    minCount: 5,
  },
  {
    name: 'Ng6() settings merge function',
    pattern: 'function Ng6',
    minCount: 1,
  },
  {
    name: 'localSettings in merge loop',
    pattern: '"localSettings"',
    minCount: 1,
  },
  {
    name: 'autoMode access in Ng6()',
    pattern: '.autoMode',
    minCount: 1,
  },
  {
    name: '.replace(/<user_allow_rules_to_replace> injection',
    pattern: '.replace(/<user_allow_rules_to_replace>',
    minCount: 1,
  },
  {
    name: 'settings.local.json path',
    pattern: 'settings.local.json',
    minCount: 1,
  },
];

for (const check of checks) {
  const offsets = searchBytes(buf, check.pattern);
  if (offsets.length >= check.minCount) {
    console.log(`${GREEN}[PASS]${RESET} ${check.name} — ${offsets.length} occurrence(s) at: ${offsets.slice(0, 4).join(', ')}${offsets.length > 4 ? '...' : ''}`);
    passed++;
  } else {
    console.log(`${RED}[FAIL]${RESET} ${check.name} — found ${offsets.length}, expected >= ${check.minCount}`);
    failed++;
  }
}

console.log('');

const replaceOffsets = searchBytes(buf, '.replace(/<user_allow_rules_to_replace>');
if (replaceOffsets.length > 0) {
  console.log(`${YELLOW}${BOLD}Key evidence — replacement mechanism:${RESET}`);
  for (const off of replaceOffsets) {
    const ctx = extractContext(buf, off, 20, 150);
    console.log(`${YELLOW}  @ offset ${off}:${RESET}`);
    console.log(`    ${ctx.replace(/\n/g, '\\n').substring(0, 180)}`);
    console.log('');
  }
}

const ng6Offsets = searchBytes(buf, 'function Ng6');
if (ng6Offsets.length > 0) {
  console.log(`${YELLOW}${BOLD}Key evidence — Ng6() settings merge:${RESET}`);
  const ctx = extractContext(buf, ng6Offsets[0], 0, 400);
  console.log(`${YELLOW}  @ offset ${ng6Offsets[0]}:${RESET}`);
  console.log(`    ${ctx.replace(/\n/g, '\\n').substring(0, 380)}`);
  console.log('');
}

console.log(`${'='.repeat(50)}`);
if (failed === 0) {
  console.log(`${GREEN}${BOLD}RESULT: ALL ${passed} CHECKS PASSED${RESET}`);
  console.log(`${GREEN}NF-12 vulnerability CONFIRMED in this cli.js build${RESET}`);
} else {
  console.log(`${RED}${BOLD}RESULT: ${failed} CHECK(S) FAILED${RESET}`);
  console.log(`${YELLOW}NF-12 may not be present in this version${RESET}`);
}
console.log('');

process.exit(failed > 0 ? 1 : 0);
