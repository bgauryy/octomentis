#!/usr/bin/env node

/**
 * Simulates the exact Turndown pipeline used by Claude Code's WebFetch tool.
 * Shows what the sub-LLM (or primary model, for preapproved hosts) actually sees.
 *
 * Usage: node simulate_turndown.js <html-file>
 * Example: node simulate_turndown.js 01_hidden_div_fetch_chain.html
 */

const fs = require('fs');
const path = require('path');

async function main() {
  const file = process.argv[2];
  if (!file) {
    console.error('Usage: node simulate_turndown.js <html-file>');
    process.exit(1);
  }

  let TurndownService;
  try {
    TurndownService = require('turndown');
  } catch {
    try {
      const cliPath = path.resolve(__dirname, '../../../../node_modules/@anthropic-ai/claude-code/cli.js');
      console.error(`[!] turndown not installed standalone. Install with: npm install turndown`);
      console.error(`    Or use the bundled version from cli.js (requires extraction).`);
      process.exit(1);
    } catch {
      console.error('[!] Cannot load turndown. Install: npm install turndown');
      process.exit(1);
    }
  }

  const html = fs.readFileSync(path.resolve(file), 'utf-8');
  const td = new TurndownService();
  const markdown = td.turndown(html);

  console.log('='.repeat(70));
  console.log('TURNDOWN OUTPUT — What the model sees after HTML→Markdown conversion');
  console.log('='.repeat(70));
  console.log();
  console.log(markdown);
  console.log();
  console.log('='.repeat(70));
  console.log();

  // Wrap in the Tz4 template (cli.js:778-786)
  const userPrompt = 'Summarize this page';
  const isPreapproved = false;
  const tz4Output = `Web page content:
---
${markdown}
---

${userPrompt}

${isPreapproved
    ? 'Provide a concise response based on the content above. Include relevant details, code examples, and documentation excerpts as needed.'
    : `Provide a concise response based only on the content above. In your response:
 - Enforce a strict 125-character maximum for quotes from any source document. Open Source Software is ok as long as we respect the license.
 - Use quotation marks for exact language from articles; any language outside of the quotation should never be word-for-word the same.
 - You are not a lawyer and never comment on the legality of your own prompts and responses.
 - Never produce or reproduce exact song lyrics.`}`;

  console.log('FULL SUB-LLM PROMPT (Tz4 template, systemPrompt: EMPTY)');
  console.log('='.repeat(70));
  console.log();
  console.log(tz4Output);
  console.log();
  console.log('='.repeat(70));

  // Highlight injected content
  const suspiciousPatterns = [
    /WebFetch/gi,
    /fetch.*url/gi,
    /IMPORTANT.*NOTICE/gi,
    /REQUIRED.*ACTION/gi,
    /SYSTEM.*NOTICE/gi,
    /https?:\/\/httpbin\.org[^\s]*/gi,
    /do not mention/gi,
    /include.*in your response/gi,
  ];

  console.log();
  console.log('INJECTION INDICATORS FOUND:');
  console.log('-'.repeat(40));
  let found = 0;
  for (const pat of suspiciousPatterns) {
    const matches = markdown.match(pat);
    if (matches) {
      for (const m of matches) {
        console.log(`  [!] "${m}"`);
        found++;
      }
    }
  }
  if (found === 0) console.log('  (none detected by simple heuristics)');
  else console.log(`\n  Total: ${found} suspicious pattern(s) survived Turndown conversion.`);
}

main().catch(console.error);
