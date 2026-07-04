(function () {
  const OPS_HEALTH_ACTIONS = [
    "ops.health.summary.v2",
    "ops.health.players",
    "ops.health.farms"
  ];

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
