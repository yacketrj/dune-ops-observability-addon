(function () {
  const samplePlayers = [
    {
      name: "Local Test Player",
      level: 42,
      faction: "Atreides",
      guild: "Preview Guild",
      status: "Online",
      map: "Survival_1",
      lastSeen: "Now"
    },
    {
      name: "Deep Desert Scout",
      level: 58,
      faction: "Fremen",
      guild: "Sietch Patrol",
      status: "Online",
      map: "Deep Desert",
      lastSeen: "3 minutes ago"
    },
    {
      name: "Spice Harvester",
      level: 31,
      faction: "Harkonnen",
      guild: "Industrial Wing",
      status: "Offline",
      map: "Hagga Basin",
      lastSeen: "2 hours ago"
    }
  ];

  const sampleCapabilities = [
    {
      category: "Population & Activity",
      status: "supported",
      source: "leadership.players.list",
      notes: "Player totals, online status, faction counts, and recent activity fields can be derived from player summary data."
    },
    {
      category: "Progression",
      status: "partial",
      source: "player level fields",
      notes: "Level rollups are available when the player summary payload includes level data."
    },
    {
      category: "Guild & Faction",
      status: "partial",
      source: "player guild/faction fields",
      notes: "Guild and faction rollups depend on the fields present in the bridge payload."
    },
    {
      category: "Economy",
      status: "unavailable",
      source: "not exposed",
      notes: "No spice, solari, exchange, tax, or market source is available to the addon MVP."
    },
    {
      category: "Inventory & Items",
      status: "unavailable",
      source: "not exposed",
      notes: "No inventory, item, container, or asset source is available to the addon MVP."
    }
  ];

  const bridgeFallbackCapabilities = [
    {
      category: "Population & Activity",
      status: "supported",
      source: "leadership.players.list",
      notes: "The current bridge exposes read-only player summary data."
    },
    {
      category: "Progression",
      status: "partial",
      source: "player summary payload",
      notes: "Progression views depend on whether level fields are present in the bridge response."
    },
    {
      category: "Guild & Faction",
      status: "partial",
      source: "player summary payload",
      notes: "Guild and faction support depends on whether those fields are present in the bridge response."
    },
    {
      category: "Economy",
      status: "unavailable",
      source: "not exposed",
      notes: "Economy KPI panels require a future reviewed bridge source."
    },
    {
      category: "Inventory & Items",
      status: "unavailable",
      source: "not exposed",
      notes: "Inventory KPI panels require a future reviewed bridge source."
    }
  ];

  function isConsoleIframe() {
    return window.parent !== window && Boolean(window.DuneAddon);
  }

  function normalizeCapabilities(result, fallback) {
    if (Array.isArray(result)) return result;
    if (result && Array.isArray(result.capabilities)) return result.capabilities;
    return fallback;
  }

  const providers = {
    sample: {
      name: "sample",
      label: "Preview sample data",
      async listPlayers() {
        return samplePlayers;
      },
      async describeKpiCapabilities() {
        return sampleCapabilities;
      }
    },
    bridge: {
      name: "bridge",
      label: "Dune Docker Console bridge",
      async listPlayers() {
        const result = await window.DuneAddon.request("leadership.players.list");
        return result.players || result || [];
      },
      async describeKpiCapabilities() {
        try {
          const result = await window.DuneAddon.request("analytics.capabilities");
          return normalizeCapabilities(result, bridgeFallbackCapabilities);
        } catch (_error) {
          return bridgeFallbackCapabilities;
        }
      }
    }
  };

  function currentProvider() {
    return isConsoleIframe() ? providers.bridge : providers.sample;
  }

  window.DuneOpsProviders = {
    currentProvider,
    providers
  };
}());
