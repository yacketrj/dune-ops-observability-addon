const statusEl = document.querySelector("#status");
const outputEl = document.querySelector("#output");
const buttonEl = document.querySelector("#check-players");

function writeStatus(text, className) {
  if (!statusEl) return;
  statusEl.textContent = text;
  statusEl.className = className || "";
}

function writeOutput(value) {
  if (!outputEl) return;
  outputEl.textContent = typeof value === "string" ? value : JSON.stringify(value, null, 2);
}

function getProvider() {
  if (!window.DuneOpsProviders) {
    throw new Error("Addon data providers failed to load.");
  }
  return window.DuneOpsProviders.currentProvider();
}

async function checkBridge() {
  try {
    const provider = getProvider();
    const players = await provider.listPlayers();
    if (provider.name === "bridge") {
      writeStatus("Connected to Dune Docker Console. Showing live bridge data.", "status-ok");
    } else {
      writeStatus("Preview mode. Showing sample data because the addon is not running inside the Console iframe.", "status-info");
    }
    writeOutput(players);
  } catch (error) {
    writeStatus("Unable to read player summary from the configured data provider.", "status-warn");
    writeOutput(error.message || String(error));
  }
}

writeStatus(
  window.parent === window
    ? "Preview mode. This is expected when opened directly; sample data is available for layout testing."
    : "Console iframe mode. Ready to check bridge access.",
  window.parent === window ? "status-info" : "status-ok"
);
if (buttonEl) buttonEl.addEventListener("click", checkBridge);
