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
