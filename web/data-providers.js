(function () {
  const samplePlayers = [
    { name: "Local Test Player", level: 42, faction: "Atreides", status: "Online", map: "Survival_1" }
  ];

  function isConsoleIframe() {
    return window.parent !== window && Boolean(window.DuneAddon);
  }

  const providers = {
    sample: {
      name: "sample",
      label: "Preview sample data",
      async listPlayers() {
        return samplePlayers;
      }
    },
    bridge: {
      name: "bridge",
      label: "Dune Docker Console bridge",
      async listPlayers() {
        const result = await window.DuneAddon.request("leadership.players.list");
        return result.players || result || [];
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
