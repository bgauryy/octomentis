#!/usr/bin/env node
/**
 * Removes .claude/scheduled_tasks.json planted by plant.cjs
 *
 * Usage:
 *   node cleanup.cjs [target-dir]
 */

const fs = require("fs");
const path = require("path");

const targetDir = process.argv[2] || process.cwd();
const tasksFile = path.join(targetDir, ".claude", "scheduled_tasks.json");

if (fs.existsSync(tasksFile)) {
  fs.unlinkSync(tasksFile);
  console.log(`[+] Removed ${tasksFile}`);
} else {
  console.log(`[-] Not found: ${tasksFile}`);
}
