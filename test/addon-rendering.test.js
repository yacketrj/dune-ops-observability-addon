// Behavioral regression tests for the SourceResult envelope refactor
// (F-1, F-3, F-4, C-4 in docs/SECURITY-ARCHITECTURE-GAP-ANALYSIS.md).
//
// These tests load the real web/index.html into a jsdom window, execute the
// real web/dune-addon-bridge.js, web/data-providers.js, and web/addon.js
// against it (not reimplemented copies), replace the active provider with a
// test double that returns controlled SourceResult envelopes, trigger a
// refresh, and assert on the actual rendered DOM text — this is what
// directly proves the false-zero and "all sources online" defects are
// fixed, not just that the underlying functions return the right shape.
//
// This replaces C-4's substring check (`js.includes('"unavailable"')`),
// which only proved the string existed somewhere in the source file, not
// that any renderer actually consumed it correctly — which is exactly why
// F-1 shipped and went undetected for as long as it did.

import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { JSDOM } from "jsdom";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..");

function readWeb(path) {
  return readFileSync(join(ROOT, "web", path), "utf8");
}

// Builds a fresh addon DOM + real scripts for each test, so no state leaks
// between tests (module-scope variables like lastSuccessfulReadAt in
// addon.js are otherwise shared across the whole process).
function loadAddon() {
  const html = readWeb("index.html").replace(
    /<script src="([^"]+)"><\/script>/g,
    "" // strip the real <script> tags; we eval the files ourselves below so
       // we can control load order and inject the mock provider in between.
  );

  const dom = new JSDOM(html, { runScripts: "dangerously", url: "https://example.invalid/" });
  const { window } = dom;

  // web/dune-addon-bridge.js and web/data-providers.js are IIFEs that only
  // touch `window`/`document` — safe to eval directly in the jsdom context.
  window.eval(readWeb("dune-addon-bridge.js"));
  window.eval(readWeb("data-providers.js"));

  return { dom, window };
}

// Replaces window.DuneOpsProviders.currentProvider() with a test double
// that returns exactly the SourceResult envelopes the test wants, then
// evals the real addon.js (which calls getProvider() -> currentProvider()
// itself, both on initial load and on every refresh).
function installMockProvider(window, methods) {
  const provider = {
    name: "bridge",
    label: "Mock bridge provider (test)",
    actions: [],
    ...methods
  };
  window.DuneOpsProviders.currentProvider = () => provider;
}

function unavailable(reason = "not_implemented", source = "ops.test.mock") {
  return { status: "unavailable", data: null, reason, source };
}

function live(data) {
  return { status: "live", data, reason: null, source: null };
}

function text(window, selector) {
  const el = window.document.querySelector(selector);
  return el ? el.textContent : null;
}

function runAddon(window) {
  window.eval(readWeb("addon.js"));
}

async function flushAsync() {
  // refreshAll() is async; addon.js's module-scope `refreshAll()` call and
  // any button-click handler both need microtasks (Promise.allSettled,
  // several `await`s) to resolve before the DOM reflects the result.
  await new Promise((resolve) => setTimeout(resolve, 0));
  await new Promise((resolve) => setTimeout(resolve, 0));
  await new Promise((resolve) => setTimeout(resolve, 0));
}

// ── F-1: unsupported/errored bridge data must never render as a false zero ──

test("renderActivity shows 'Not available', not 0, when the source is unavailable", async () => {
  const { window } = loadAddon();
  installMockProvider(window, {
    getActivity: async () => unavailable("not_implemented", "ops.activity.summary")
  });
  runAddon(window);
  await flushAsync();

  assert.equal(text(window, "#act-total"), "—", "act-total must show a dash, not 0 or a stale value");
  assert.equal(text(window, "#act-online"), "—");
  assert.notEqual(text(window, "#act-total"), "0", "must never render the literal string 0 for an unavailable source");

  const note = window.document.querySelector("#act-availability-note");
  assert.ok(note, "availability note element must exist");
  assert.equal(note.hidden, false, "availability note must be shown when the source is unavailable");
  assert.match(note.textContent, /not available/i);
});

test("renderCombat shows 'Not available', not 0, when the source is unavailable", async () => {
  const { window } = loadAddon();
  installMockProvider(window, {
    getCombat: async () => unavailable("bridge_error", "ops.combat.deaths")
  });
  runAddon(window);
  await flushAsync();

  assert.equal(text(window, "#cmb-total"), "—");
  assert.equal(text(window, "#cmb-kd"), "—");
  assert.notEqual(text(window, "#cmb-total"), "0");
  assert.equal(window.document.querySelector("#cmb-availability-note").hidden, false);
});

test("renderInventory shows 'Not available', not 0, for a not-yet-implemented Core route", async () => {
  const { window } = loadAddon();
  installMockProvider(window, {
    getInventory: async () => unavailable("not_implemented", "ops.inventory.summary")
  });
  runAddon(window);
  await flushAsync();

  assert.equal(text(window, "#inv-items"), "—");
  assert.equal(text(window, "#inv-invs"), "—");
  assert.equal(text(window, "#inv-crafted"), "—");
  assert.notEqual(text(window, "#inv-items"), "0");
});

test("a rejected provider promise (not just an {status:'unavailable'} envelope) also renders as unavailable, not 0", async () => {
  // This is the exact defect this session found beyond the original gap
  // analysis: Promise.allSettled's rejection branch used to collapse to a
  // bare `{}`, which every renderXxx() read as "no fields present" and
  // rendered as 0 — indistinguishable from a real empty payload.
  const { window } = loadAddon();
  installMockProvider(window, {
    getEconomy: async () => { throw new Error("network error"); }
  });
  runAddon(window);
  await flushAsync();

  assert.equal(text(window, "#eco-holders"), "—");
  assert.equal(text(window, "#eco-supply"), "—");
  assert.notEqual(text(window, "#eco-holders"), "0");
  assert.equal(window.document.querySelector("#eco-availability-note").hidden, false);
});

test("renderOpsAggregate distinguishes a real zero-row result from an unavailable source", async () => {
  const { window } = loadAddon();
  installMockProvider(window, {
    getOpsHealth: async () => live({ summary: { players: { total: 0 }, farms: { total: 0 } } })
  });
  runAddon(window);
  await flushAsync();

  // A genuinely empty (but real) result renders numeric 0s, not dashes —
  // this is deliberately different from the unavailable case below.
  assert.equal(text(window, "#metric-total"), "0");
  const emptyState = window.document.querySelector("#empty-state");
  assert.equal(emptyState.hidden, false, "empty-state note shows for a real empty result");
  assert.match(emptyState.textContent, /live aggregate data, not placeholder/i);
});

test("renderOpsAggregate shows dashes (not fabricated 0s) when ops health itself is unavailable", async () => {
  const { window } = loadAddon();
  installMockProvider(window, {
    getOpsHealth: async () => unavailable("request_failed", "ops.health.*")
  });
  runAddon(window);
  await flushAsync();

  assert.equal(text(window, "#metric-total"), "—");
  assert.equal(text(window, "#metric-online"), "—");
  const emptyState = window.document.querySelector("#empty-state");
  assert.equal(emptyState.hidden, false);
  assert.match(emptyState.textContent, /not available/i);
});

// ── F-3: preview/sample data must be visually distinguishable from live data ──

test("preview mode sets a distinct data-provider attribute on <body>", async () => {
  const { window } = loadAddon();
  // Do not install a mock "bridge" provider — leave currentProvider() at
  // its real default, which resolves to the sample provider outside an
  // iframe (window.parent === window in this jsdom context).
  runAddon(window);
  await flushAsync();

  assert.equal(window.document.body.dataset.provider, "sample", "preview mode must be identifiable via a body attribute the CSS watermark keys off");
});

test("live bridge mode does not set the preview data-provider attribute", async () => {
  const { window } = loadAddon();
  installMockProvider(window, {
    getActivity: async () => live({ totalPlayers: 5 })
  });
  runAddon(window);
  await flushAsync();

  assert.equal(window.document.body.dataset.provider, "bridge");
});

// ── F-4: the status banner must reflect real per-source success, not a hardcoded claim ──

test("status banner reports a degraded source count instead of claiming all sources are online", async () => {
  const { window } = loadAddon();
  installMockProvider(window, {
    getOpsHealth: async () => live({ summary: { players: { total: 3 }, farms: { total: 1 } } }),
    getActivity: async () => live({ totalPlayers: 3 }),
    getCombat: async () => unavailable("not_implemented", "ops.combat.deaths"),
    getResources: async () => unavailable("not_implemented", "ops.resources.summary"),
    getEconomy: async () => live({ totalCurrencyHolders: 1 }),
    getInventory: async () => unavailable("not_implemented", "ops.inventory.summary"),
    getLocation: async () => unavailable("not_implemented", "ops.location.activity"),
    getSoc: async () => unavailable("not_implemented", "ops.soc.summary"),
    getPrometheusHealth: async () => unavailable("not_implemented", "ops.health.prometheus")
  });
  runAddon(window);
  await flushAsync();

  const status = text(window, "#status");
  assert.doesNotMatch(status, /all .* sources online/i, "must not claim all sources are online when 5 of 9 are unavailable");
  assert.match(status, /3 of 9/, "must report the real live/total source count");
});

test("status banner correctly claims all sources online only when every source truly is", async () => {
  const { window } = loadAddon();
  const okData = { status: "live", data: {}, reason: null, source: null };
  installMockProvider(window, {
    getOpsHealth: async () => live({ summary: { players: { total: 1 }, farms: { total: 1 } } }),
    getActivity: async () => okData,
    getCombat: async () => okData,
    getResources: async () => okData,
    getEconomy: async () => okData,
    getInventory: async () => okData,
    getLocation: async () => okData,
    getSoc: async () => okData,
    getPrometheusHealth: async () => okData
  });
  runAddon(window);
  await flushAsync();

  assert.match(text(window, "#status"), /all 9 observability sources online/i);
});

// ── Non-fabrication guardrail: unavailable sources must not appear in the diagnostics output as if they were real ──

test("diagnostics output records unavailable sources by status, not by omission", async () => {
  const { window } = loadAddon();
  installMockProvider(window, {
    getEconomy: async () => unavailable("not_implemented", "ops.economy.summary")
  });
  runAddon(window);
  await flushAsync();

  const output = JSON.parse(text(window, "#output"));
  assert.ok(output.sources, "diagnostics output must include a per-source status breakdown");
  assert.equal(output.sources.economy.status, "unavailable");
  assert.equal(output.sources.economy.reason, "not_implemented");
});
