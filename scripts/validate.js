#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const manifest = JSON.parse(fs.readFileSync('addon.json', 'utf8'));

for (const field of ['id', 'name', 'description', 'author', 'version', 'type']) {
  if (!manifest[field]) {
    console.error(`${field} is required`);
    process.exit(1);
  }
}

if (manifest.schemaVersion !== 1) {
  console.error('schemaVersion must be 1');
  process.exit(1);
}

if (manifest.type !== 'ui') {
  console.error('type must be ui');
  process.exit(1);
}

function listJsFiles(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...listJsFiles(fullPath));
    } else if (entry.isFile() && entry.name.endsWith('.js')) {
      files.push(fullPath);
    }
  }
  return files;
}

for (const file of listJsFiles('web')) {
  try {
    execFileSync(process.execPath, ['--check', file], { stdio: 'inherit' });
  } catch (error) {
    console.error(`Syntax check failed for ${file}`);
    process.exit(1);
  }
}

console.log(`Addon manifest is valid: ${manifest.id} ${manifest.version}`);
