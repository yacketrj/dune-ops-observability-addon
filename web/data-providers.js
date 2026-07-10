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
    resourcesByMap: [
      { map: "Deep Desert", fields: 15, totalValue: 60000 },
      { map: "Rocky Outcrop", fields: 10, totalValue: 35000 },
      { map: "Sietch Tabr", fields: 9, totalValue: 30000 }
    ],
    spiceFieldsBySize: [
      { size: "Small", map: "Survival_1", active_fields: 3, total_value: 12000, currently_active: 2, max_active: 5 },
      { size: "Medium", map: "Survival_1", active_fields: 2, total_value: 25000, currently_active: 1, max_active: 3 },
      { size: "Large", map: "Survival_1", active_fields: 1, total_value: 15000, currently_active: 1, max_active: 2 },
      { size: "Small", map: "Deep Desert", active_fields: 4, total_value: 8000, currently_active: 3, max_active: 5 },
      { size: "Medium", map: "Deep Desert", active_fields: 2, total_value: 18000, currently_active: 2, max_active: 3 }
    ],
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

  const providers = {
    sample: {
      name: "sample",
      label: "Preview sample data (all sources)",
      actions: ALL_ACTIONS,
      async getOpsHealth() {
        return sampleOpsHealth;
      },
      async getActivity() {
        return sampleActivity;
      },
      async getCombat() {
        return sampleCombat;
      },
      async getResources() {
        return sampleResources;
      },
      async getEconomy() {
        return sampleEconomy;
      },
      async getInventory() {
        return sampleInventory;
      },
      async getLocation() {
        return sampleLocation;
      },
      async getSoc() {
        return sampleSoc;
      },
      async getPrometheusHealth() {
        return samplePrometheusHealth;
      }
    },
    bridge: {
      name: "bridge",
      label: "Dune Docker Console bridge (all sources)",
      actions: ALL_ACTIONS,
      async getOpsHealth() {
        const [summary, players, farms] = await Promise.all([
          bridgeRequest("ops.health.summary.v2"),
          bridgeRequest("ops.health.players"),
          bridgeRequest("ops.health.farms")
        ]);
        return { summary, players, farms };
      },
      async getActivity() {
        const data = await bridgeRequest("ops.activity.summary");
        if (!data || data.error) {
          // Fallback: derive total/online from ops.health.players
          const players = await bridgeRequest("ops.health.players");
          if (!players || players.error) return sampleActivity;
          const total = players.total || 0;
          const online = (players.onlineStatus && players.onlineStatus.Online) || 0;
          return {
            totalPlayers: total, onlinePlayers: online,
            activeLast1h: null, activeLast24h: null, activeLast7d: null,
            inactivePlayers: null, returningPlayers: null, newPlayers: null,
            playersDead: null,
            guildActivity: [], factionActivity: [], mapActivity: [],
            _source: "ops.health.players (fallback)"
          };
        }
        return data;
      },
      async getCombat() {
        const data = await bridgeRequest("ops.combat.deaths");
        if (!data || data.error || data.status === "planned") return sampleCombat;
        return data;
      },
      async getResources() {
        const data = await bridgeRequest("ops.resources.summary");
        if (!data || data.error || data.status === "planned" || !data.resourcesByType) return sampleResources;
        return data;
      },
      async getEconomy() {
        const data = await bridgeRequest("ops.economy.summary");
        if (!data || data.error || data.status === "planned") return sampleEconomy;
        return data;
      },
      async getInventory() {
        const data = await bridgeRequest("ops.inventory.summary");
        if (!data || data.error || data.status === "planned") return sampleInventory;
        return data;
      },
      async getLocation() {
        const data = await bridgeRequest("ops.location.activity");
        if (!data || data.error || data.status === "planned") return sampleLocation;
        return data;
      },
      async getSoc() {
        const data = await bridgeRequest("ops.soc.summary");
        if (!data || data.error || data.status === "planned") return sampleSoc;
        return data;
      },
      async getPrometheusHealth() {
        const data = await bridgeRequest("ops.health.prometheus");
        if (!data || data.error || data.status === "planned") return samplePrometheusHealth;
        return data;
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
