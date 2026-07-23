(function () {
  const OPS_HEALTH_ACTIONS = [
    "ops.health.summary.v2",
    "ops.health.players",
    "ops.health.farms"
  ];

  const OPS_ACTIVITY_ACTIONS = [
    "ops.activity.summary"
  ];

  const OPS_COMBAT_ACTIONS = [
    "ops.combat.deaths"
  ];

  const OPS_RESOURCES_ACTIONS = [
    "ops.resources.summary"
  ];

  const OPS_ECONOMY_ACTIONS = [
    "ops.economy.summary"
  ];

  const OPS_INVENTORY_ACTIONS = [
    "ops.inventory.summary"
  ];

  const OPS_LOCATION_ACTIONS = [
    "ops.location.activity"
  ];

  const OPS_SOC_ACTIONS = [
    "ops.soc.summary"
  ];

  const OPS_PROMETHEUS_ACTIONS = [
    "ops.health.prometheus"
  ];

  const samplePrometheusHealth = {
    healthy: true,
    targets: { active: 6, inactive: 0, pending: 0, total: 6 },
    services: {
      "dune-prometheus": "up",
      "dune-node": "up",
      "dune-cadvisor": "up",
      "dune-postgres": "up",
      "dune-rabbitmq-admin": "up",
      "dune-rabbitmq-game": "up"
    },
    summary: {
      avgCpuPercent: 12.5,
      avgMemoryMb: 256,
      totalRestarts: 0
    }
  };

  const ALL_ACTIONS = [].concat(
    OPS_HEALTH_ACTIONS,
    OPS_ACTIVITY_ACTIONS,
    OPS_COMBAT_ACTIONS,
    OPS_RESOURCES_ACTIONS,
    OPS_ECONOMY_ACTIONS,
    OPS_INVENTORY_ACTIONS,
    OPS_LOCATION_ACTIONS,
    OPS_SOC_ACTIONS,
    OPS_PROMETHEUS_ACTIONS
  );

  const sampleOpsHealth = {
    summary: {
      players: {
        total: 3,
        onlineStatus: {
          Online: 2,
          Offline: 1
        },
        factions: {
          Atreides: 1,
          Fremen: 1,
          Harkonnen: 1
        },
        guilds: {
          "Preview Guild": 1,
          "Sietch Patrol": 1,
          "Industrial Wing": 1
        },
        averageLevel: 44
      },
      farms: {
        total: 2,
        ready: 1,
        alive: 2
      }
    },
    players: {
      total: 3,
      onlineStatus: {
        Online: 2,
        Offline: 1
      },
      factions: {
        Atreides: 1,
        Fremen: 1,
        Harkonnen: 1
      },
      guilds: {
        "Preview Guild": 1,
        "Sietch Patrol": 1,
        "Industrial Wing": 1
      },
      averageLevel: 44
    },
    farms: {
      total: 2,
      ready: 1,
      alive: 2
    }
  };

  const sampleActivity = {
    totalPlayers: 3,
    onlinePlayers: 2,
    offlinePlayers: 1,
    activeLast1h: 1,
    activeLast24h: 3,
    activeLast7d: 3,
    sessionCount: 12,
    returningPlayers: 2,
    newPlayers: 1,
    guildActivity: [
      { guild: "Sietch Patrol", members: 2, online: 1 },
      { guild: "Industrial Wing", members: 1, online: 1 }
    ],
    factionActivity: [
      { faction: "Atreides", members: 1, online: 1 },
      { faction: "Fremen", members: 1, online: 0 },
      { faction: "Harkonnen", members: 1, online: 1 }
    ],
    mapActivity: [
      { map: "Deep Desert", actors: 5, online: 2 },
      { map: "Sietch Tabr", actors: 3, online: 1 }
    ],
    inactivePlayers: 0,
    playersDead: 1
  };

  const sampleCombat = {
    totalDeaths: 47,
    pvpDeaths: 12,
    pveDeaths: 35,
    deathsByCause: [
      { cause: "Creature Attack", count: 18 },
      { cause: "Player Kill", count: 12 },
      { cause: "Environment", count: 10 },
      { cause: "Fall", count: 5 },
      { cause: "Thirst", count: 2 }
    ],
    deathsByMap: [
      { map: "Deep Desert", count: 25 },
      { map: "Sietch Tabr", count: 12 },
      { map: "Arrakeen", count: 10 }
    ],
    topHostileNpcs: [
      { name: "Sandworm", count: 8 },
      { name: "Desert Viper", count: 5 },
      { name: "Harkonnen Guard", count: 3 }
    ],
    kdRatio: 0.26
  };

  const sampleResources = {
    totalFields: 34,
    totalValueRemaining: 125000,
    resourcesByType: [
      { type: "Spice", fields: 12, totalValue: 60000 },
      { type: "Water", fields: 8, totalValue: 32000 },
      { type: "Mineral", fields: 6, totalValue: 18000 },
      { type: "Solar", fields: 5, totalValue: 10000 },
      { type: "Organic", fields: 3, totalValue: 5000 }
    ],
    resourcesByMap: [],
    spiceFieldsBySize: [],
    gatheringSpikes: []
  };

  const sampleEconomy = {
    totalCurrencyHolders: 45,
    totalSupply: 250000,
    currencies: [
      { currencyId: "Solaris", holders: 40, totalSupply: 150000, averageBalance: 3750, minBalance: 50, maxBalance: 50000 },
      { currencyId: "Spice Tokens", holders: 25, totalSupply: 75000, averageBalance: 3000, minBalance: 10, maxBalance: 20000 },
      { currencyId: "Guild Credits", holders: 12, totalSupply: 25000, averageBalance: 2083, minBalance: 0, maxBalance: 10000 }
    ],
    activeOrders: 28,
    fulfilledOrders: 156,
    topTradedItems: [
      { templateId: "spice_ore_001", orders: 12, avgPrice: 250, minPrice: 200, maxPrice: 300 },
      { templateId: "water_001", orders: 8, avgPrice: 150, minPrice: 100, maxPrice: 200 },
      { templateId: "rifle_mk1", orders: 5, avgPrice: 1200, minPrice: 1000, maxPrice: 1500 }
    ],
    totalTaxFees: 12500
  };

  const sampleInventory = {
    totalItems: 342,
    totalInventories: 18,
    itemsByTemplate: [
      { templateId: "water_flask", count: 45, totalStack: 90 },
      { templateId: "spice_portion", count: 32, totalStack: 64 },
      { templateId: "rifle_ammo", count: 28, totalStack: 140 },
      { templateId: "bandage", count: 20, totalStack: 40 },
      { templateId: "canteen", count: 15, totalStack: 30 }
    ],
    totalCrafted: 23,
    storageUsage: [
      { inventoryId: "player_001_inv", itemCount: 24, totalStack: 48 },
      { inventoryId: "guild_001_storage", itemCount: 18, totalStack: 60 },
      { inventoryId: "player_003_inv", itemCount: 12, totalStack: 24 }
    ]
  };

  const sampleLocation = {
    activeMaps: [
      { map: "Deep Desert", players: 4, online: 2 },
      { map: "Sietch Tabr", players: 3, online: 1 },
      { map: "Arrakeen", players: 2, online: 1 }
    ],
    totalMarkers: 87,
    markersByMap: [
      { map: "Deep Desert", markers: 35 },
      { map: "Sietch Tabr", markers: 28 },
      { map: "Arrakeen", markers: 24 }
    ],
    playerDensity: [
      { map: "Deep Desert", players: 4, online: 2 },
      { map: "Sietch Tabr", players: 3, online: 1 },
      { map: "Arrakeen", players: 2, online: 1 }
    ],
    territoryPressure: []
  };

  const sampleSoc = {
    platformHealth: "Healthy",
    bridgeRequests: 47,
    bridgeErrors: 1,
    bridgeSuccessRate: 97.9,
    dataFreshness: new Date().toISOString(),
    timestamp: new Date().toISOString(),
    health: {
      players: sampleOpsHealth.players,
      farms: sampleOpsHealth.farms
    },
    activity: sampleActivity,
    economy: sampleEconomy,
    combat: sampleCombat,
    resources: sampleResources,
    inventory: sampleInventory,
    location: sampleLocation
  };

  function isConsoleIframe() {
    return window.parent !== window && Boolean(window.DuneAddon);
  }

  async function bridgeRequest(action) {
    return await window.DuneAddon.request(action);
  }

  // ── SourceResult envelope ──
  //
  // Every provider method returns this shape unconditionally, on success or
  // failure alike, so every renderXxx() in addon.js can switch on `.status`
  // before ever touching `.data`. This is the fix for the false-zero
  // rendering defect (a provider's honest "no data" response was silently
  // treated as if it were a real payload with all-zero fields once it
  // reached the DOM).
  //
  // `status` is one of:
  //   "live"        — real bridge data, successfully fetched.
  //   "preview"     — sample/fixture data (non-production; not real).
  //   "unavailable" — no real data available; `reason` explains why, `data`
  //                   is always null. Never render a number derived from an
  //                   "unavailable" result — that is exactly the anti-pattern
  //                   this envelope exists to prevent.
  //
  // `reason` (only set when status is "unavailable") is one of:
  //   "not_implemented" — Core returned {status: "planned"} for this action.
  //   "bridge_error"     — Core returned a response with `.error` set, or an
  //                         empty/falsy response.
  //   "request_failed"   — the bridge request itself rejected (network
  //                         failure, timeout, addon not running inside the
  //                         Console iframe). Previously this rejection
  //                         propagated unhandled out of the provider method
  //                         entirely; refreshAll()'s Promise.allSettled then
  //                         silently collapsed it to `{}`, which every
  //                         renderXxx() read as "all fields absent" and
  //                         rendered as 0 — the same false-zero defect as
  //                         the already-handled "planned" case, just via a
  //                         different code path.
  function liveResult(data) {
    return { status: "live", data, reason: null, source: null };
  }

  function previewResult(data) {
    return { status: "preview", data, reason: null, source: null };
  }

  function unavailableResult(reason, source) {
    return { status: "unavailable", data: null, reason, source };
  }

  async function fetchLiveOrUnavailable(action) {
    let data;
    try {
      data = await bridgeRequest(action);
    } catch (err) {
      return unavailableResult("request_failed", action);
    }
    if (!data || data.error) return unavailableResult("bridge_error", action);
    if (data.status === "planned") return unavailableResult("not_implemented", action);
    return liveResult(data);
  }

  const providers = {
    sample: {
      name: "sample",
      label: "Preview sample data (all sources)",
      actions: ALL_ACTIONS,
      async getOpsHealth() {
        return previewResult(sampleOpsHealth);
      },
      async getActivity() {
        return previewResult(sampleActivity);
      },
      async getCombat() {
        return previewResult(sampleCombat);
      },
      async getResources() {
        return previewResult(sampleResources);
      },
      async getEconomy() {
        return previewResult(sampleEconomy);
      },
      async getInventory() {
        return previewResult(sampleInventory);
      },
      async getLocation() {
        return previewResult(sampleLocation);
      },
      async getSoc() {
        return previewResult(sampleSoc);
      },
      async getPrometheusHealth() {
        return previewResult(samplePrometheusHealth);
      }
    },
    bridge: {
      name: "bridge",
      label: "Dune Docker Console bridge (all sources)",
      actions: ALL_ACTIONS,
      async getOpsHealth() {
        try {
          const [summary, players, farms] = await Promise.all([
            bridgeRequest("ops.health.summary.v2"),
            bridgeRequest("ops.health.players"),
            bridgeRequest("ops.health.farms")
          ]);
          return liveResult({ summary, players, farms });
        } catch (err) {
          return unavailableResult("request_failed", "ops.health.*");
        }
      },
      async getActivity() {
        return fetchLiveOrUnavailable("ops.activity.summary");
      },
      async getCombat() {
        return fetchLiveOrUnavailable("ops.combat.deaths");
      },
      async getResources() {
        return fetchLiveOrUnavailable("ops.resources.summary");
      },
      async getEconomy() {
        return fetchLiveOrUnavailable("ops.economy.summary");
      },
      async getInventory() {
        return fetchLiveOrUnavailable("ops.inventory.summary");
      },
      async getLocation() {
        return fetchLiveOrUnavailable("ops.location.activity");
      },
      async getSoc() {
        return fetchLiveOrUnavailable("ops.soc.summary");
      },
      async getPrometheusHealth() {
        return fetchLiveOrUnavailable("ops.health.prometheus");
      }
    }
  };

  function currentProvider() {
    return isConsoleIframe() ? providers.bridge : providers.sample;
  }

  window.DuneOpsProviders = {
    currentProvider,
    providers,
    // Exposed for tests and for any future provider implementation that
    // needs to construct a SourceResult envelope consistently.
    liveResult,
    previewResult,
    unavailableResult
  };
}());
