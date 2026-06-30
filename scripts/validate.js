#!/usr/bin/env node

const fs = require('fs');
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

console.log(`Addon manifest is valid: ${manifest.id} ${manifest.version}`);
