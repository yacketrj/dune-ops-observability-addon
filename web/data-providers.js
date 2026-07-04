(function () {
  const OPS_HEALTH_ACTIONS = [
    "ops.health.summary.v2",
    "ops.health.players",
    "ops.health.farms"
  ];

<<<<<<< ours
=======
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

>>>>>>> theirs
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

  function isConsoleIframe() {
    return window.parent !== window && Boolean(window.DuneAddon);
  }

  async function bridgeRequest(action) {
    return await window.DuneAddon.request(action);
  }

  const providers = {
    sample: {
      name: "sample",
      label: "Preview sample OPS health data",
      actions: OPS_HEALTH_ACTIONS,
      async getOpsHealth() {
        return sampleOpsHealth;
<<<<<<< ours
=======
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
>>>>>>> theirs
      }
    },
    bridge: {
      name: "bridge",
      label: "Dune Docker Console OPS health bridge",
      actions: OPS_HEALTH_ACTIONS,
      async getOpsHealth() {
        const [summary, players, farms] = await Promise.all([
          bridgeRequest("ops.health.summary.v2"),
          bridgeRequest("ops.health.players"),
          bridgeRequest("ops.health.farms")
        ]);
        return { summary, players, farms };
<<<<<<< ours
=======
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
      },
      async getSoc() {
        return await bridgeRequest("ops.soc.summary");
      },
      async getPrometheusHealth() {
        return await bridgeRequest("ops.health.prometheus");
>>>>>>> theirs
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
