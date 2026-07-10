// faction-tagger.js — Automatic faction/spice color tagging.
// Scans the DOM for text containing faction names or "spice" and applies
// data-faction or data-spice attributes to parent elements.
// Runs on load + watches for mutations.

(function initFactionTagger() {
  const FACTION_KEYWORDS = {
    atreides: /atreides/i,
    harkonnen: /harkonnen/i,
    fremen: /fremen/i,
  };

  const SPICE_KEYWORDS = /spice|melange/i;

  function tagElement(el, attr) {
    if (!el || el.nodeType !== 1) return;
    // Don't override if already tagged
    if (!el.hasAttribute(attr)) {
      el.setAttribute(attr, "");
    }
  }

  function tagRow(row, text) {
    if (!text || !row) return;
    const lower = text.toLowerCase();
    for (const [faction, re] of Object.entries(FACTION_KEYWORDS)) {
      if (re.test(lower)) {
        row.setAttribute("data-faction", faction);
        return;
      }
    }
    if (SPICE_KEYWORDS.test(lower)) {
      row.setAttribute("data-spice", "");
    }
  }

  function scanTableRows() {
    // Scan all table rows for faction/spice text
    document.querySelectorAll("tr, .metric-card, .summary-grid, .card, article").forEach(function(row) {
      if (row.hasAttribute("data-faction") || row.hasAttribute("data-spice")) return;
      const text = (row.textContent || "").slice(0, 200);
      tagRow(row, text);
    });

    // Scan individual cells
    document.querySelectorAll("td, th, span, .section-heading, h2, h3, .panel-title").forEach(function(cell) {
      if (cell.hasAttribute("data-faction") || cell.hasAttribute("data-spice")) return;
      const text = (cell.textContent || "").slice(0, 100);
      const lower = text.toLowerCase();
      
      if (SPICE_KEYWORDS.test(lower)) {
        cell.setAttribute("data-spice", "");
        // Also tag parent row
        const parentRow = cell.closest("tr");
        if (parentRow && !parentRow.hasAttribute("data-spice")) {
          parentRow.setAttribute("data-spice", "");
        }
      }

      for (const [faction, re] of Object.entries(FACTION_KEYWORDS)) {
        if (re.test(lower)) {
          cell.setAttribute("data-faction", faction);
          const parentRow = cell.closest("tr");
          if (parentRow && !parentRow.hasAttribute("data-faction")) {
            parentRow.setAttribute("data-faction", faction);
          }
          break;
        }
      }
    });
  }

  // Inherit faction from parent window (for addon iframe)
  function inheritFromParent() {
    try {
      var faction = parent.document.documentElement.getAttribute("data-faction");
      if (faction) {
        document.documentElement.setAttribute("data-faction", faction);
      }
    } catch (e) {
      // cross-origin — ignore
    }
  }

  // Initial scan
  inheritFromParent();
  scanTableRows();

  // Watch for dynamic content
  var observer = new MutationObserver(function(mutations) {
    var hasNewNodes = false;
    mutations.forEach(function(m) {
      if (m.addedNodes.length > 0) hasNewNodes = true;
      if (m.type === "attributes" && m.attributeName === "data-tab" && m.target.classList.contains("active")) {
        hasNewNodes = true;
      }
    });
    if (hasNewNodes) {
      setTimeout(scanTableRows, 100); // debounce
    }
  });

  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["class", "data-tab"]
  });
})();
