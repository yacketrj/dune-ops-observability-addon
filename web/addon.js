const statusEl = document.querySelector("#status");
const outputEl = document.querySelector("#output");
const buttonEl = document.querySelector("#refresh-players");
const playersBodyEl = document.querySelector("#players-body");
const providerLabelEl = document.querySelector("#provider-label");
const emptyStateEl = document.querySelector("#empty-state");
const metricTotalEl = document.querySelector("#metric-total");
const metricOnlineEl = document.querySelector("#metric-online");
const metricOfflineEl = document.querySelector("#metric-offline");
const metricFactionsEl = document.querySelector("#metric-factions");

function writeStatus(text, className) {
  if (!statusEl) return;
  statusEl.textContent = text;
  statusEl.className = className || "";
}

function writeOutput(value) {
  if (!outputEl) return;
  outputEl.textContent = typeof value === "string" ? value : JSON.stringify(value, null, 2);
}

function setMetric(element, value) {
  if (!element) return;
  element.textContent = String(value);
}

function getProvider() {
  if (!window.DuneOpsProviders) {
    throw new Error("Addon data providers failed to load.");
  }
  return window.DuneOpsProviders.currentProvider();
}

function readField(player, names, fallback) {
  for (const name of names) {
    if (Object.prototype.hasOwnProperty.call(player, name) && player[name] !== null && player[name] !== undefined && player[name] !== "") {
      return player[name];
    }
  }
  return fallback;
}

function normalizePlayer(player) {
  return {
    name: readField(player, ["name", "playerName", "username", "displayName"], "Unknown player"),
    level: readField(player, ["level", "playerLevel"], "—"),
    faction: readField(player, ["faction", "house", "allegiance"], "Unknown"),
    guild: readField(player, ["guild", "guildName", "company", "clan"], "—"),
    status: readField(player, ["status", "onlineStatus", "state"], "Unknown"),
    location: readField(player, ["map", "location", "zone", "server", "serviceLocation"], "—"),
    lastSeen: readField(player, ["lastSeen", "last_seen", "lastOnline", "updatedAt"], "—")
  };
}

function clearTable() {
  if (!playersBodyEl) return;
  while (playersBodyEl.firstChild) {
    playersBodyEl.removeChild(playersBodyEl.firstChild);
  }
}

function appendCell(row, value, className) {
  const cell = document.createElement("td");
  cell.textContent = String(value);
  if (className) cell.className = className;
  row.appendChild(cell);
}

function statusClass(status) {
  return String(status).toLowerCase() === "online" ? "pill pill-online" : "pill";
}

function renderPlayers(players) {
  const normalized = players.map(normalizePlayer);
  clearTable();

  const onlineCount = normalized.filter((player) => String(player.status).toLowerCase() === "online").length;
  const offlineCount = normalized.length - onlineCount;
  const factionCount = new Set(normalized.map((player) => player.faction).filter((faction) => faction && faction !== "Unknown")).size;

  setMetric(metricTotalEl, normalized.length);
  setMetric(metricOnlineEl, onlineCount);
  setMetric(metricOfflineEl, offlineCount);
  setMetric(metricFactionsEl, factionCount);

  if (emptyStateEl) {
    emptyStateEl.hidden = normalized.length > 0;
  }

  for (const player of normalized) {
    const row = document.createElement("tr");
    appendCell(row, player.name);
    appendCell(row, player.level);
    appendCell(row, player.faction);
    appendCell(row, player.guild);
    appendCell(row, player.status, statusClass(player.status));
    appendCell(row, player.location);
    appendCell(row, player.lastSeen);
    playersBodyEl.appendChild(row);
  }

  return { total: normalized.length, online: onlineCount, offline: offlineCount, factions: factionCount };
}

async function refreshPlayerSummary() {
  try {
    const provider = getProvider();
    if (providerLabelEl) providerLabelEl.textContent = `Provider: ${provider.label}`;

    const players = await provider.listPlayers();
    const playerList = Array.isArray(players) ? players : [];
    const totals = renderPlayers(playerList);

    if (provider.name === "bridge") {
      writeStatus("Connected to Dune Docker Console. Showing live bridge data.", "status-ok");
    } else {
      writeStatus("Preview mode. Showing sample data because the addon is not running inside the Console iframe.", "status-info");
    }

    writeOutput({ provider: provider.name, totals });
  } catch (error) {
    renderPlayers([]);
    writeStatus("Unable to read player summary from the configured data provider.", "status-warn");
    writeOutput(error.message || String(error));
  }
}

writeStatus(
  window.parent === window
    ? "Preview mode. This is expected when opened directly; sample data is available for layout testing."
    : "Console iframe mode. Ready to read player summary from the bridge.",
  window.parent === window ? "status-info" : "status-ok"
);

if (buttonEl) buttonEl.addEventListener("click", refreshPlayerSummary);
refreshPlayerSummary();
