-- Sensitive-review SQL candidates from preserved Release 0.2 discovery scripts.
-- These queries are aggregate or metadata-oriented but are not approved for bridge telemetry yet.

-- High-value table row counts: broad metadata aggregate; useful internally, not bridge-approved.
-- Tables include player, actor, economy, guild, marker, and map-related tables.

-- Game event type counts: includes event taxonomy and map grouping; needs review.

-- Game event custom data keys: JSON key inventory may reveal payload structure; hold.

-- Event log meta keys: JSON key inventory may reveal internal detail; hold.

-- Item template summary: item/economy metadata; hold.

-- Item operation function summary: implementation-specific function/template grouping; hold.

-- Exchange order summary: price distribution by template; economy-sensitive; hold.

-- Fulfilled exchange order summary: aggregate completion data; review later.

-- Currency balance summary: player-wallet-derived aggregate economy data; hold.

-- Resource field summary: map/dimension/resource data is location-adjacent; review later.

-- Spice field type summary: world-state/location-adjacent operational data; review later.

-- Dungeon completion summary: activity aggregate; likely useful after review.

-- Landsraad progress summary: faction/guild/player progress fields; hold.

-- Marker summary: location-adjacent map/dimension grouping; review later.

-- Player marker summary: player-discovery-derived location-adjacent data; hold.
