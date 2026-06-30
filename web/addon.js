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
    return { source: "mock", players: mockPlayers };
  }
  const result = await window.DuneAddon.request("leadership.players.list");
  return { source: "bridge", players: result.players || result || [] };
}

async function checkBridge() {
  try {
    const result = await getPlayers();
    writeStatus(`Bridge check complete using ${result.source} data.`, result.source === "bridge" ? "status-ok" : "status-warn");
    writeOutput(result.players);
  } catch (error) {
    writeStatus("Bridge check failed.", "status-warn");
    writeOutput(error.message || String(error));
  }
}

writeStatus(window.parent === window ? "Local preview mode. Using mock data." : "Console iframe mode. Bridge ready for checks.", window.parent === window ? "status-warn" : "status-ok");
if (buttonEl) buttonEl.addEventListener("click", checkBridge);
