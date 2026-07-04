const statusEl = document.querySelector("#status");
const outputEl = document.querySelector("#output");
const buttonEl = document.querySelector("#refresh-players");
const playersBodyEl = document.querySelector("#players-body");
const providerLabelEl = document.querySelector("#provider-label");
const emptyStateEl = document.querySelector("#empty-state");
const metricTotalEl = document.querySelector("#metric-total");
const metricOnlineEl = document.querySelector("#metric-online");
const metricOfflineEl = document.querySelector("#metric-offline");
const metricFarmsEl = document.querySelector("#metric-farms");
const opsSourceHealthEl = document.querySelector("#ops-source-health");
const opsSourceHealthNoteEl = document.querySelector("#ops-source-health-note");
const opsFreshnessEl = document.querySelector("#ops-freshness");
const opsFreshnessNoteEl = document.querySelector("#ops-freshness-note");
const opsPlayerImpactEl = document.querySelector("#ops-player-impact");
const opsPlayerImpactNoteEl = document.querySelector("#ops-player-impact-note");
const opsOperatorStatusEl = document.querySelector("#ops-operator-status");
const opsOperatorStatusNoteEl = document.querySelector("#ops-operator-status-note");
const kpiActiveRateEl = document.querySelector("#kpi-active-rate");
const kpiActiveRateNoteEl = document.querySelector("#kpi-active-rate-note");
const kpiAverageLevelEl = document.querySelector("#kpi-average-level");
const kpiAverageLevelNoteEl = document.querySelector("#kpi-average-level-note");
const kpiTopFactionEl = document.querySelector("#kpi-top-faction");
const kpiTopFactionNoteEl = document.querySelector("#kpi-top-faction-note");
const kpiTopGuildEl = document.querySelector("#kpi-top-guild");
const kpiTopGuildNoteEl = document.querySelector("#kpi-top-guild-note");

const STALE_READ_THRESHOLD_MS = 5 * 60 * 1000;
let lastSuccessfulReadAt = null;
let previousTotals = null;

function writeStatus(text, className) {
  if (!statusEl) return;
  statusEl.textContent = text;
  statusEl.className = className || "";
}

function writeOutput(value) {
  if (!outputEl) return;
  outputEl.textContent = typeof value === "string" ? value : JSON.stringify(value, null, 2);
}

function setText(element, value) {
  if (!element) return;
  element.textContent = String(value);
}

function getProvider() {
  if (!window.DuneOpsProviders) {
    throw new Error("Addon data providers failed to load.");
  }
  return window.DuneOpsProviders.currentProvider();
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

function formatRefreshTime(date) {
  return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

function formatAge(milliseconds) {
  if (milliseconds < 1000) return "now";
  const seconds = Math.floor(milliseconds / 1000);
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  return `${hours}h ago`;
}

function asNumber(value, fallback = 0) {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : fallback;
}

function valueFromKeys(source, keys, fallback = 0) {
  if (!source || typeof source !== "object") return fallback;
  for (const key of keys) {
    if (Object.prototype.hasOwnProperty.call(source, key)) {
      return asNumber(source[key], fallback);
    }
  }
  return fallback;
}

function countFromObject(source, targetKey) {
  if (!source || typeof source !== "object") return null;
  const normalizedTarget = String(targetKey).toLowerCase();
  for (const [key, value] of Object.entries(source)) {
    if (String(key).toLowerCase() === normalizedTarget) return asNumber(value, 0);
  }
  return null;
}

function topCountLabel(source) {
  if (!source || typeof source !== "object") return { name: "—", count: 0 };
  let topName = "—";
  let topCount = 0;
  for (const [name, value] of Object.entries(source)) {
    const count = asNumber(value, 0);
    if (name && count > topCount) {
      topName = name;
      topCount = count;
    }
  }
  return { name: topName, count: topCount };
}

function normalizeOpsHealth(raw) {
  const envelope = raw && typeof raw === "object" ? raw : {};
  const summary = envelope.summary && typeof envelope.summary === "object" ? envelope.summary : envelope;
  const players = envelope.players || summary.players || {};
  const farms = envelope.farms || summary.farms || {};
  const onlineStatus = players.onlineStatus || players.online_status || {};
  const online = countFromObject(onlineStatus, "online") ?? valueFromKeys(players, ["online", "onlineCount", "online_count"], 0);
  const offlineFromStatus = countFromObject(onlineStatus, "offline");
  const total = valueFromKeys(players, ["total", "count", "playerCount", "player_count"], 0);
  const offline = offlineFromStatus ?? valueFromKeys(players, ["offline", "offlineCount", "offline_count"], Math.max(total - online, 0));
  const farmTotal = valueFromKeys(farms, ["total", "count", "farmCount", "farm_count"], 0);
  const readyFarms = valueFromKeys(farms, ["ready", "readyCount", "ready_count"], 0);
  const aliveFarms = valueFromKeys(farms, ["alive", "aliveCount", "alive_count"], 0);
  const factions = players.factions || players.byFaction || players.factionCounts || {};
  const guilds = players.guilds || players.byGuild || players.guildCounts || {};
  const topFaction = topCountLabel(factions);
  const topGuild = topCountLabel(guilds);
  const averageLevel = valueFromKeys(players, ["averageLevel", "avgLevel", "average_level", "avg_level"], null);

  return {
    raw,
    summary,
    players,
    farms,
    totals: {
      total,
      online,
      offline,
      farms: farmTotal,
      readyFarms,
      aliveFarms
    },
    kpis: {
      activeRate: total > 0 ? Math.round((online / total) * 100) : null,
      averageLevel: averageLevel === null ? null : asNumber(averageLevel, null),
      topFaction,
      topGuild
    },
    capabilities: summary.capabilities || players.capabilities || {},
    hasRows: total > 0 || farmTotal > 0
  };
}

function playerDeltaLabel(current, previous) {
  if (!previous) return "Baseline";
  const totalDelta = current.total - previous.total;
  const onlineDelta = current.online - previous.online;
  const farmDelta = current.farms - previous.farms;
  const signedTotal = totalDelta > 0 ? `+${totalDelta}` : String(totalDelta);
  const signedOnline = onlineDelta > 0 ? `+${onlineDelta}` : String(onlineDelta);
  const signedFarms = farmDelta > 0 ? `+${farmDelta}` : String(farmDelta);

  if (totalDelta === 0 && onlineDelta === 0 && farmDelta === 0) return "No change";
  return `${signedTotal} players / ${signedOnline} online / ${signedFarms} farms`;
}

function updateOpsHealth(provider, totals, refreshedAt, error) {
  const isBridge = provider && provider.name === "bridge";
  const now = refreshedAt || new Date();
  const lastAge = lastSuccessfulReadAt ? now.getTime() - lastSuccessfulReadAt.getTime() : null;
  const isStale = lastAge !== null && lastAge > STALE_READ_THRESHOLD_MS;
  const sourceHealth = error ? "Degraded" : isBridge ? "Bridge live" : "Preview";
  const sourceNote = error
    ? "The active provider returned an error."
    : isBridge
      ? "Reading Release 0.3 OPS health aggregates through the Console bridge."
      : "Using sample OPS health aggregates because the addon is not inside the Console iframe.";
  const freshness = error
    ? lastSuccessfulReadAt ? "Stale" : "No read"
    : isStale ? "Stale" : "Fresh";
  const freshnessNote = lastSuccessfulReadAt
    ? `Last successful read: ${formatRefreshTime(lastSuccessfulReadAt)} (${formatAge(lastAge || 0)}).`
    : "No successful read has completed in this session.";
  const impactLabel = totals ? playerDeltaLabel(totals, previousTotals) : "Unavailable";
  const impactNote = totals
    ? previousTotals
      ? `Current players: ${totals.total}; online: ${totals.online}; farms: ${totals.farms}. Previous players: ${previousTotals.total}; online: ${previousTotals.online}; farms: ${previousTotals.farms}.`
      : `Baseline established with ${totals.total} players, ${totals.online} online, and ${totals.farms} farm sites.`
    : "No OPS health summary is available for comparison.";
  const operatorStatus = error
    ? "Action needed"
    : isBridge && !isStale
      ? "Healthy"
      : isBridge && isStale
        ? "Stale"
        : "Preview";
  const operatorNote = error
    ? "Provider read failed. Confirm the Console bridge, ops:read approval, and Release 0.3 Core actions."
    : isBridge
      ? "Bridge read completed through the approved ops:read boundary."
      : "Open through Dune Docker Console Addons to validate live Release 0.3 bridge data.";

  setText(opsSourceHealthEl, sourceHealth);
  setText(opsSourceHealthNoteEl, sourceNote);
  setText(opsFreshnessEl, freshness);
  setText(opsFreshnessNoteEl, freshnessNote);
  setText(opsPlayerImpactEl, impactLabel);
  setText(opsPlayerImpactNoteEl, impactNote);
  setText(opsOperatorStatusEl, operatorStatus);
  setText(opsOperatorStatusNoteEl, operatorNote);

  return {
    sourceHealth,
    freshness,
    playerImpact: impactLabel,
    operatorStatus,
    lastSuccessfulRead: lastSuccessfulReadAt ? lastSuccessfulReadAt.toISOString() : null,
    staleThresholdSeconds: STALE_READ_THRESHOLD_MS / 1000
  };
}

function renderKpis(snapshot) {
  const { totals, kpis } = snapshot;
  setText(kpiActiveRateEl, kpis.activeRate === null ? "—" : `${kpis.activeRate}%`);
  setText(kpiActiveRateNoteEl, totals.total > 0 ? `${totals.online} of ${totals.total} players are online.` : "No player aggregate rows available.");
  setText(kpiAverageLevelEl, kpis.averageLevel === null ? "—" : Math.round(kpis.averageLevel));
  setText(kpiAverageLevelNoteEl, kpis.averageLevel === null ? "Average level is not present in this aggregate payload." : "Average level returned by the OPS health aggregate.");
  setText(kpiTopFactionEl, kpis.topFaction.name);
  setText(kpiTopFactionNoteEl, kpis.topFaction.count > 0 ? `${kpis.topFaction.count} players in this faction.` : "Faction aggregate is not present in this payload.");
  setText(kpiTopGuildEl, kpis.topGuild.name);
  setText(kpiTopGuildNoteEl, kpis.topGuild.count > 0 ? `${kpis.topGuild.count} players in this guild.` : "Guild aggregate is not present in this payload.");

  return {
    activeRate: kpis.activeRate,
    averageLevel: kpis.averageLevel,
    topFaction: kpis.topFaction.name,
    topGuild: kpis.topGuild.name
  };
}

function renderOpsAggregate(snapshot, refreshedAt) {
  const { totals } = snapshot;
  clearTable();

  setText(metricTotalEl, totals.total);
  setText(metricOnlineEl, totals.online);
  setText(metricOfflineEl, totals.offline);
  setText(metricFarmsEl, totals.farms);

  if (emptyStateEl) {
    emptyStateEl.hidden = snapshot.hasRows;
    emptyStateEl.textContent = snapshot.hasRows
      ? ""
      : "OPS health bridge returned zero player rows and zero farm rows. This is live aggregate data, not placeholder content.";
  }

  if (playersBodyEl) {
    const row = document.createElement("tr");
    appendCell(row, "OPS aggregate");
    appendCell(row, totals.total);
    appendCell(row, totals.online, statusClass(totals.online > 0 ? "online" : "offline"));
    appendCell(row, totals.offline);
    appendCell(row, totals.farms);
    appendCell(row, `${totals.readyFarms} ready / ${totals.aliveFarms} alive`);
    appendCell(row, formatRefreshTime(refreshedAt));
    playersBodyEl.appendChild(row);
  }

  return { totals, kpis: renderKpis(snapshot) };
}

async function refreshOpsHealth() {
  let provider;

  try {
    provider = getProvider();
    if (providerLabelEl) providerLabelEl.textContent = `Provider: ${provider.label}`;

    const rawOpsHealth = await provider.getOpsHealth();
    const snapshot = normalizeOpsHealth(rawOpsHealth);
    const refreshedAt = new Date();
    const previousSnapshot = previousTotals;
    const summary = renderOpsAggregate(snapshot, refreshedAt);
    lastSuccessfulReadAt = refreshedAt;
    const opsHealth = updateOpsHealth(provider, summary.totals, refreshedAt, null);

    if (provider.name === "bridge") {
      writeStatus("Connected to Dune Docker Console. Showing live Release 0.3 OPS health bridge data.", "status-ok");
    } else {
      writeStatus("Preview mode. Showing sample OPS health aggregate data because the addon is not running inside the Console iframe.", "status-info");
    }

    writeOutput({
      provider: provider.name,
      sourceMode: provider.name === "bridge" ? "live-ops-health-bridge" : "preview-sample",
      lastRefresh: refreshedAt.toISOString(),
      actions: provider.actions || [],
      totals: summary.totals,
      previousTotals: previousSnapshot,
      opsHealth,
      kpis: summary.kpis,
      resultShape: {
        hasSummaryPlayers: Boolean(snapshot.summary && snapshot.summary.players),
        hasSummaryFarms: Boolean(snapshot.summary && snapshot.summary.farms),
        hasPlayersAggregate: Boolean(snapshot.players && Object.keys(snapshot.players).length),
        hasFarmsAggregate: Boolean(snapshot.farms && Object.keys(snapshot.farms).length)
      },
      raw: rawOpsHealth
    });

    previousTotals = summary.totals;
  } catch (error) {
    const refreshedAt = new Date();
    renderOpsAggregate(normalizeOpsHealth({}), refreshedAt);
    const opsHealth = updateOpsHealth(provider, null, refreshedAt, error);
    writeStatus("Unable to read Release 0.3 OPS health data from the configured provider.", "status-warn");
    writeOutput({
      provider: provider ? provider.name : "unknown",
      sourceMode: provider && provider.name === "bridge" ? "live-ops-health-bridge" : "unknown",
      lastRefresh: refreshedAt.toISOString(),
      opsHealth,
      error: error.message || String(error)
    });
  }
}

writeStatus(
  window.parent === window
    ? "Preview mode. This is expected when opened directly; sample OPS health aggregate data is available for layout testing."
    : "Console iframe mode. Ready to read Release 0.3 OPS health from the bridge.",
  window.parent === window ? "status-info" : "status-ok"
);

if (buttonEl) buttonEl.addEventListener("click", refreshOpsHealth);
refreshOpsHealth();
