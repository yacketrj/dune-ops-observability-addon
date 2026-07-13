#!/usr/bin/env node
// scrape-augments.js — Scrapes augment stat roll counts from dune.gaming.tools
// Usage: node scrape-augments.js [--output augment-rolls.json]
// Each augment page is fetched and the number of Grade 5 stat rows is counted.
// This equals the required StatRolls array length for pre-augmented items.

const fs = require("fs");
const https = require("https");

const BASE = "https://dune.gaming.tools";
const AUGMENT_LIST_URL = `${BASE}/items/augment`;
const CACHE_DIR = `${__dirname}/.augment-cache`;

// Known augment template IDs from the game catalog
// Generated from runtime/data/admin-items.json filtered by /T\d+_Augment/ + category:schematics
// These are the schematic IDs that appear in the augment picker.
// The script fetches the corresponding gaming.tools page for each.

if (!fs.existsSync(CACHE_DIR)) fs.mkdirSync(CACHE_DIR, { recursive: true });

function fetch(url) {
  return new Promise((resolve, reject) => {
    const cacheKey = `${CACHE_DIR}/${Buffer.from(url).toString("hex")}.html`;
    if (fs.existsSync(cacheKey)) {
      return resolve(fs.readFileSync(cacheKey, "utf8"));
    }
    https.get(url, { headers: { "User-Agent": "DuneConsole/1.0" } }, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        fs.writeFileSync(cacheKey, data);
        resolve(data);
      });
    }).on("error", reject);
  });
}

function extractRollCount(html, augmentName) {
  // Count Grade 5 stat rows. Each stat row represents one StatRoll.
  // Example pattern: "5Damage-7.0%Attack Stamina Cost-18.0% to -20.0%Block Stamina Cost-18.0% to -20.0%"
  // The Grade 5 row contains all stats for that grade.

  // Find the Grade 5 section
  const grade5Section = html.match(/<td[^>]*>5<\/td>([\s\S]*?)(?=<td[^>]*>\d+<\/td>|<\/tr>)/);
  if (!grade5Section) {
    // Some augments have min grade > 1 - use the highest available grade
    const grades = [...html.matchAll(/<td[^>]*>(\d+)<\/td>/g)];
    if (grades.length === 0) return null;
    const maxGrade = Math.max(...grades.map((g) => parseInt(g[1])));
    const maxSection = html.match(new RegExp(`<td[^>]*>${maxGrade}<\\/td>([\\s\\S]*?)(?=<td[^>]*>\\d+<\\/td>|<\\/tr>)`));
    if (!maxSection) return null;
  }

  const section = grade5Section || html;

  // Count "StatValue" occurrences which indicate stat columns
  const statCount = (section[0] || section).match(/<td[^>]*StatValue[^>]*>/g);
  if (statCount) return statCount.length;

  // Fallback: count percentage patterns in the grade row
  const pctMatches = html.match(/<td[^>]*>5<\/td>[\s\S]*?(?=<\/tr>)/);
  if (pctMatches) {
    const stats = pctMatches[0].match(/%/g);
    return stats ? stats.length : null;
  }

  return null;
}

async function main() {
  console.log("Scraping augment list...");
  const listHtml = await fetch(AUGMENT_LIST_URL);

  // Extract augment page URLs from the listing
  const links = [...listHtml.matchAll(/href="(\/items\/t6_augment_[^"]+)"/gi)];
  const uniqueLinks = [...new Set(links.map((l) => l[1]))];

  console.log(`Found ${uniqueLinks.length} augment pages`);

  const results = {};
  let done = 0;

  for (const link of uniqueLinks) {
    const url = BASE + link;
    const augmentId = link.split("/").pop();

    try {
      console.log(`[${++done}/${uniqueLinks.length}] ${augmentId}`);
      const html = await fetch(url);
      const count = extractRollCount(html, augmentId);
      if (count) {
        results[augmentId] = count;
      }
    } catch (e) {
      console.error(`  Failed: ${e.message}`);
    }

    // Rate limit
    await new Promise((r) => setTimeout(r, 200));
  }

  // Also generate the mapping in duneDb.js format
  let duneCode = "// Auto-generated augment roll counts from dune.gaming.tools\n";
  duneCode += "// Generated: " + new Date().toISOString() + "\n";
  duneCode += "const AUGMENT_ROLL_COUNTS = {\n";
  for (const [id, count] of Object.entries(results).sort()) {
    duneCode += `  "${id}": ${count},\n`;
  }
  duneCode += "};\n";

  const outputFile = process.argv.includes("--output")
    ? process.argv[process.argv.indexOf("--output") + 1]
    : `${__dirname}/augment-roll-counts.json`;

  fs.writeFileSync(outputFile, JSON.stringify(results, null, 2));
  fs.writeFileSync(`${__dirname}/augment-roll-counts.js`, duneCode);

  console.log(`\nDone! ${Object.keys(results).length} augments mapped`);
  console.log(`Output: ${outputFile}`);
  console.log(`JS: ${__dirname}/augment-roll-counts.js`);
}

main().catch(console.error);
