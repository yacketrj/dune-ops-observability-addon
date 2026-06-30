const statusEl = document.querySelector("#status");
const outputEl = document.querySelector("#output");
const buttonEl = document.querySelector("#check-players");

const mockPlayers = [
  { name: "Local Test Player", level: 42, faction: "Atreides", status: "Online", map: "Survival_1" }
];

function writeStatus(text, className) {
  if (!statusEl) return;
  statusEl.textContent = text;
  statusEl.className = className || "";
}

function writeOutput(value) {
  if (!outputEl) return;
  outputEl.textContent = typeof value === "string" ? value : JSON.stringify(value, null, 2);
}

async function getPlayers() {
  if (window.parent === window || !window.DuneAddon) {
    return { source: "sample", players: mockPlayers };
  }
  const result = await window.DuneAddon.request("leadership.players.list");
  return { source: "console", players: result.players || result || [] };
}

async function checkBridge() {
  try {
    const result = await getPlayers();
    if (result.source === "console") {
      writeStatus("Connected to Dune Docker Console. Showing live bridge data.", "status-ok");
    } else {
      writeStatus("Preview mode. Showing sample data because the addon is not running inside the Console iframe.", "status-info");
    }
    writeOutput(result.players);
  } catch (error) {
    writeStatus("Unable to read player summary from the Console bridge.", "status-warn");
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
