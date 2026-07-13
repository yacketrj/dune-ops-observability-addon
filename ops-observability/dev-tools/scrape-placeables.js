#!/usr/bin/env node
// scrape-placeables.js — Scrapes building resource requirements from dune.gaming.tools
// Usage: node scrape-placeables.js [--output placeable-resources.json]
// Fetches each placeable page and extracts "Building Ingredients" section.

const fs = require("fs");
const https = require("https");

const BASE = "https://dune.gaming.tools";
const PLACEABLE_LIST_URL = `${BASE}/placeables`;
const CACHE_DIR = `${__dirname}/.placeable-cache`;

// Catalog IDs from runtime/data/admin-items.json (buildings + placeables)
// These are read at runtime. The script maps gaming.tools page names to our catalog IDs.

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

function extractIngredients(html) {
  // Find "Building Ingredients" section
  const ingredientSection = html.match(/Building Ingredients([\s\S]*?)(?=Craftable Items|Dune Awakening Version|<div class="mt-4)/);
  if (!ingredientSection) return null;

  const section = ingredientSection[1];

  // Parse ingredient lines: "Plastanium Ingotx140" -> name + quantity
  const ingredients = [...section.matchAll(/([A-Za-z\s-]+?)x(\d+)/g)];

  const resources = {};
  for (const match of ingredients) {
    const name = match[1].trim();
    const qty = parseInt(match[2]);
    if (name && qty > 0 && !name.match(/^Health|Inventory|Power|Backpack/i)) {
      resources[name] = qty;
    }
  }

  return Object.keys(resources).length > 0 ? resources : null;
}

// Map gaming.tools page names to our catalog IDs
const PAGE_TO_CATALOG = {
  "advancedwearablesfabricator_placeable": "AdvancedWearablesFabricator_Patent",
  "advancedsurvivalfabricator_placeable": "AdvancedSurvivalFabricator_Patent",
  "advancedweaponsfabricator_placeable": "AdvancedWeaponsFabricator_Patent",
  "advancedvehiclesfabricator_placeable": "AdvancedVehiclesFabricator_Patent",
  "fabricator_placeable": "BasicFabricator_Patent",
  "wearablesfabricator_placeable": "WearablesFabricator_Patent",
  "personalfabricator_placeable": "PersonalFabricator_Patent",
  "survivalfabricator_placeable": "SurvivalFabricator_Patent",
  "weaponsfabricator_placeable": "WeaponsFabricator_Patent",
  "vehiclefabricator_placeable": "VehicleFabricator_Patent",
  "moddingstation_placeable": "AugmentStation_Patent",
  "smallchemicalrefinery": "SmallChemicalRefinery",
  "mediumchemicalrefinery_placeable": "MediumChemicalRefinery_Patent",
  "smallorerefinery": "SmallOreRefinery",
  "mediumorerefinery_placeable": "MediumOreRefinery_Patent",
  "largeorerefinery_placeable": "LargeOreRefinery_Patent",
  "largespicerefinery_placeable": "LargeSpiceRefinery_Patent",
  "mediumspicerefinery_placeable": "MediumSpiceRefinery_Patent",
  "bloodpurifier_placeable": "BloodWaterExtraction_Patent",
  "improvedbloodpurifier_placeable": "BloodWaterExtractionAdvanced_Patent",
  "fremendeathstill_placeable": "FremenDeathstill_Patent",
  "advancedfremendeathstill_placeable": "AdvancedFremenDeathstill_Patent",
  "fuelpoweredgenerator_placeable": "FuelPoweredGenerator_Patent",
  "solarpanel_placeable": "SolarGenerator_Patent",
  "windtrap_placeable": "Windtrap_Patent",
  "largewindtrap_placeable": "LargeWindtrap_Patent",
  "totem_placeable": "AdvancedSubFiefConsole_Patent",
  "totem_small_placeable": "Totem_Small_Patent",
  "mediumstoragecontainer_placeable": "MediumStorageContainer_Patent",
  "storagecontainer_placeable": "StorageContainer_Patent",
  "chest_placeable": "BasicContainer_Patent",
  "mediumwatercistern_placeable": "MediumWaterCistern_Patent",
  "largewatercistern_placeable": "LargeWaterCistern_Patent",
  "pentashieldsurfacehorizontal_placeable": "PentashieldSurfaceHorizontal_Patent",
  "pentashieldsurfacevertical_placeable": "PentashieldSurfaceVertical_Patent",
  "repairstation_placeable": "RepairStation_Patent",
  "recycler_placeable": "Recycler_Patent",
  "spicesilo_placeable": "SpiceSilo_Patent",
  "basiclighting_placeable": "BasicLighting_Patent",
  "developer_storage_container_placeable": "Developer_Storage_Container_Patent",
  "polarfabricator_placeable": "PolarFabricator_Patent",
  "icerefinery_placeable": "IceRefinery_Patent",
  "spicegenerator_placeable": "SpiceGenerator_Patent",
  "windturbinedirectional_placeable": "WindturbineDirectional_Patent",
  "windturbineomni_placeable": "WindTurbineOmni_Patent",
};

async function main() {
  console.log("Scraping placeable pages...");

  const results = {};
  const urls = Object.keys(PAGE_TO_CATALOG);
  let done = 0, found = 0;

  for (const pageUrl of urls) {
    const url = `${BASE}/placeables/${pageUrl}`;
    const catalogId = PAGE_TO_CATALOG[pageUrl];

    try {
      console.log(`[${++done}/${urls.length}] ${pageUrl} -> ${catalogId}`);
      const html = await fetch(url);
      const ingredients = extractIngredients(html);

      if (ingredients) {
        results[catalogId] = ingredients;
        found++;
        console.log(`  ${Object.keys(ingredients).length} ingredients: ${JSON.stringify(ingredients).substring(0, 80)}`);
      } else {
        console.log(`  No ingredients found`);
      }
    } catch (e) {
      console.error(`  Failed: ${e.message}`);
    }

    await new Promise((r) => setTimeout(r, 200));
  }

  // Generate output
  const outputFile = process.argv.includes("--output")
    ? process.argv[process.argv.indexOf("--output") + 1]
    : `${__dirname}/placeable-resources.json`;

  fs.writeFileSync(outputFile, JSON.stringify(results, null, 2));

  // Generate TypeScript code
  let tsCode = "// Auto-generated placeable resources from dune.gaming.tools\n";
  tsCode += `// Generated: ${new Date().toISOString()}\n`;
  tsCode += "// Copy into PLACEABLE_RESOURCES in placeableResources.ts\n\n";
  for (const [id, resources] of Object.entries(results).sort()) {
    const entries = Object.entries(resources)
      .map(([name, qty]) => `    { name: "${name}", qty: ${qty} }`)
      .join(",\n");
    tsCode += `  "${id}": [\n${entries}\n  ],\n`;
  }
  fs.writeFileSync(`${__dirname}/placeable-resources-generated.ts`, tsCode);

  console.log(`\nDone! ${found}/${urls.length} placeables scraped`);
  console.log(`JSON: ${outputFile}`);
  console.log(`TS: ${__dirname}/placeable-resources-generated.ts`);
}

main().catch(console.error);
