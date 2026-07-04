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




  const ALL_ACTIONS = [].concat(
    OPS_HEALTH_ACTIONS,
    OPS_ACTIVITY_ACTIONS,
    OPS_COMBAT_ACTIONS,
    OPS_RESOURCES_ACTIONS,
    OPS_ECONOMY_ACTIONS,
    OPS_INVENTORY_ACTIONS,
    OPS_LOCATION_ACTIONS,
    OPS_SOC_ACTIONS
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
    inactivePlayers: 0
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
        return await bridgeRequest("ops.activity.summary");
      },
      async getCombat() {
        return await bridgeRequest("ops.combat.deaths");
      },
      async getResources() {
        return await bridgeRequest("ops.resources.summary");
      },
      async getEconomy() {
        return await bridgeRequest("ops.economy.summary");
      },
      async getInventory() {
        return await bridgeRequest("ops.inventory.summary");
      },
      async getLocation() {
        return await bridgeRequest("ops.location.activity");
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
