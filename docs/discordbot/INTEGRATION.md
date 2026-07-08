# Discord Bot Integration — Addon Work Stream

## Architecture Overview

```
Discord Server                    Dune Docker Host
──────────────                    ────────────────
                                  ┌────────────────────┐
  /dune activity ─────┐          │ Console WebUI (8088)│
  /dune combat        │   HTTP   │  ┌──────────────┐   │
  /dune resources     │  Bearer  │  │Discord Adapter│   │
  /dune economy       ├─────────►│  │   routes.js   │   │
  /dune inventory     │  Token   │  └──────┬───────┘   │
  /dune location      │          │         │           │
  /dune soc           │          │    OPS Bridge       │
  /dune prometheus    │          │    Actions          │
  /dune dashboard     │          │         │           │
  /dune population    │          │         ▼           │
  /dune status        │          │  ┌──────────────┐   │
  /dune backups       │          │  │  OPS Addon   │   │
  /dune broadcast ────┘          │  │ (WebUI panel) │   │
                                 │  └──────────────┘   │
  Discord Bot                    └────────────────────┘
  (Node.js container)                      │
  host network                     Docker Socket
  localhost:8088                    Game Server
```

## Route Mapping — Bot Commands ↔ Adapter ↔ Addon

| Bot Command | Adapter Route | Addon Bridge Action | Status |
|-------------|--------------|-------------------|--------|
| `/dune health` | `GET /api/integrations/discord/health` | None (built-in) | Live |
| `/dune status` | `POST /api/integrations/discord/status` | None (runner.js) | Live |
| `/dune readiness` | `POST /api/integrations/discord/readiness` | None (runner.js) | Live |
| `/dune services` | `POST /api/integrations/discord/services` | None (runner.js) | Live |
| `/dune population` | `POST /api/integrations/discord/population` | None (derived from status) | Live |
| `/dune activity` | `POST /api/integrations/discord/ops/activity` | `ops.activity.summary` | Planned |
| `/dune combat` | `POST /api/integrations/discord/ops/combat` | `ops.combat.deaths` | Planned |
| `/dune resources` | `POST /api/integrations/discord/ops/resources` | `ops.resources.summary` | Planned |
| `/dune economy` | `POST /api/integrations/discord/ops/economy` | `ops.economy.summary` | Planned |
| `/dune inventory` | `POST /api/integrations/discord/ops/inventory` | `ops.inventory.summary` | Planned |
| `/dune location` | `POST /api/integrations/discord/ops/location` | `ops.location.activity` | Planned |
| `/dune soc` | `POST /api/integrations/discord/ops/soc` | `ops.soc.summary` | Planned |
| `/dune prometheus` | `POST /api/integrations/discord/ops/prometheus` | `ops.health.prometheus` | Planned |
| `/dune dashboard` | `POST /api/integrations/discord/ops/dashboard` | Aggregated summary | Planned |

**Planned** means the adapter route exists and returns a placeholder response. Addon bridge actions need to be wired into the route handlers for live data.

## Token Flow

```
1. Operator generates a random shared secret.
2. Secret is written to core-main/runtime/secrets/bot-api-token.txt
3. Console adapter reads it via DUNE_BOT_API_TOKEN_FILE env var:
     DUNE_BOT_API_TOKEN_FILE=/repo/runtime/secrets/bot-api-token.txt
4. Bot reads it via .env:
     DUNE_DISCORD_ADAPTER_TOKEN=<same value>
5. Bot sends Authorization: Bearer <token> on every adapter request.
6. Adapter validates with constant-time comparison.
```

## RBAC Alignment

| Discord Role | Adapter Capability Tier | Addon Permission |
|-------------|------------------------|-----------------|
| Observer | `observer` | `ops:read` |
| Moderator | `moderator` | `ops:read` |
| Admin | `admin` | `ops:read` |

The addon's single permission (`ops:read`) maps to the adapter's observer+ capability tiers.
No write permissions exist in the addon. The bot's write commands (broadcast, maintenance, etc.) are gated behind `DUNE_DISCORD_WRITES_ENABLED=true` and do not touch addon data.

## Configuration Locations

| Config | Repo | File |
|--------|------|------|
| Adapter enablement | `core-main` | `docker-compose.web.yml` (environment section) |
| Adapter enablement (test) | `e2e-integration` | `docker-compose.web.yml` (mirrors core-main) |
| Bot API token | `core-main` | `runtime/secrets/bot-api-token.txt` |
| Bot API token (test) | `e2e-integration` | `secrets/bot-api-token.txt` |
| Bot .env | `dune-awakening-selfhost-discordbot` | `.env` |

## Impact on Addon Work Stream

- **Zero code changes required** in the addon.
- The adapter now defines 9 OPS routes under `/api/integrations/discord/ops/*`. These return placeholder responses until bridge actions are wired.
- When upstream merges the adapter PR, the addon team can rebase and implement the route handlers.
- The addon's `ops:read` permission remains unchanged.
- All 9 OPS routes are read-only — no write exposure from the addon side.

## Testing

### Verify Adapter is Enabled
```bash
docker exec redblink-dune-docker-console printenv | grep DUNE_DISCORD
# Expected: DUNE_DISCORD_ADAPTER_ENABLED=true
```

### Verify Bot Can Reach Adapter
```bash
docker logs dune-discord-bot | grep "discord.ready"
```

### Verify OPS Routes Are Defined
```bash
curl -H "Authorization: Bearer <token>" http://localhost:8088/api/integrations/discord/health | jq .routes
# Should include ops/activity, ops/combat, etc.
```

### Full Integration Smoke Test
From the bot repo:
```bash
npm run smoke:adapter
npm run security:api
```

## Sources

- Bot repo: `yacketrj/dune-awakening-selfhost-discordbot`
- Core docker PR: `Red-Blink/dune-awakening-selfhost-docker#63`
- Addon repo: `yacketrj/dune-ops-observability-addon`
- Adapter contract: `docs/discord-control-bot/api-adapter-contract.md` (in core docker PR)
