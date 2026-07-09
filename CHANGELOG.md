# Changelog

All notable changes to the Zombies mod are documented here. This file is
the authoritative record of what has changed; the README describes current
behaviour only.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.4.0] — 2026-07-08

- **Removed the dedicated hit sound (`zombies_hit.ogg`).** In practice it
  competed with the weapon's own punch sound: mobs_redo plays a weapon-bound
  punch sound on every hit (via `on_punch`), while the mob's `damage` sound was
  throttled to once per 2.5s — so the two overlapped and the zombie-specific
  grunt was mostly buried. Removed the file, the `damage = 'zombies_hit'`
  mapping in the `noise` table, and its README/license credits. Zombies now
  play no mob-specific sound when struck; only the weapon's punch sound plays
  (that sound is bound to the weapon by mobs_redo, not to the mob, and was
  always present). No other sounds changed — `groan.ogg`, `eating-brains.ogg`,
  and the occasional `zombies_death.ogg` are unaffected.

## [1.3.0] — 2026-07-08

Loot rebalance to slow down how fast drops accumulate, especially when
farming dungeon spawners. Drop CHANCES and tiers were retuned; the two-tier
structure (common any-death vs. player-kill-only valuables) is unchanged.

- **Common scraps flattened and reduced.** All five common drops are now a
  uniform 1-in-10, min 1 / max 1 (previously torch 1-in-5 max 3, apple 1-in-6
  max 5, leather 1-in-10 max 3, etc.). This is the main fix for loot piling up
  too fast — the common tier no longer floods the ground.
- **Tier reshuffle.** `bonemeal:bone` and `farming:bread` moved from valuables
  into the common (any-death) tier at 1-in-10. `default:iron_lump` (1-in-15)
  and `default:steel_ingot` (1-in-20) moved the other way, from common into
  the player-kill-only valuables tier.
- **Valuable quantities trimmed.** `mese_crystal_fragment` max 2 → 1; the
  relocated iron/steel/gold_lump are all min 1 / max 1. `zombies:tooth`
  unchanged (1-in-50, 1–3) so taming currency is unaffected.
- **Currency retuned.** `minegeld_cent_25` max 2 → 3; `minegeld` max 3 → 2;
  `minegeld_10` 1-in-200 → 1-in-100; `minegeld_50` 1-in-300 → 1-in-250. Net:
  slightly more mid-tier cash, fewer big single notes.
- Bags unchanged. Looting behaviour unchanged (still an extra rarity-gated
  roll per item on player kills).

## [1.2.0] — 2026-07-07

- **Looting enchantment support (x_enchanting-compatible).** Killing a zombie
  with a Looting-enchanted weapon now boosts drops in a tiered, rarity-
  preserving way. For each drop, with probability `looting / (looting + 1)`
  (I ≈ 50%, II ≈ 67%, III ≈ 75%) the item gets one EXTRA roll at its OWN drop
  chance — an additional lottery ticket at the same rarity, not a guaranteed
  drop. Applied to both tiers (common scraps and player-kill-only valuables).
  Effective rates: tooth 1-in-50 → ~1-in-30 at Looting III; a 1-in-1500 diamond
  sword → ~1-in-860 at Looting III (still rare). Only runs on player kills;
  additive on top of base drops.
    - Deliberately does NOT mirror x_enchanting's raw bonus formula, which
      ignores per-item drop chance and would make a 1-in-1000 sword drop ~75%
      of the time at Looting III — destroying the rarity balance. The extra
      roll is gated by each item's own chance instead.
    - Reads the enchant level from the weapon's item meta (`is_looting`), the
      same field x_enchanting writes. **No enchanting mod is required:** with
      none installed the field is absent, `get_float` returns 0, and looting is
      a silent no-op. The mod calls no x_enchanting API, so nothing breaks
      without it.
    - `x_enchanting` added to `optional_depends` (load-order only; not required
      for correctness since no API is called).

## [1.1.0] — 2026-07-07

Sound additions by TechnoWolfTV. Two new CC0 (public domain) sound files
sourced from Freesound, downmixed to mono and loudness-normalized to sit
with the existing audio (see license.txt for full credits).

- **Dedicated hit sound.** Striking a zombie now plays a distinct impact
  sound (`zombies_hit.ogg`, "Zombie Hit" by Under7dude, CC0) via the
  mobs_redo `damage` trigger, replacing the reused groan. Still routed
  through the existing per-entity combat throttle (once per 2.5s), so
  rapid strikes don't machine-gun the sound.
  *(Superseded in 1.4.0: this sound was removed for competing with the
  weapon's own punch sound.)*

- **Occasional death cry (Option B).** Death is now usually silent. A new
  death sound (`zombies_death.ogg`, "zombie death" by dreggsome, CC0)
  plays on a 1-in-4 (25%) roll per death, fired from a shared `on_die`
  hook rather than the mobs_redo `sounds.death` slot. The `death` key was
  removed from the sound table and the obsolete death special-case removed
  from the mob_sound wrapper; the on_die roll is the sole death-sound path.

- **Rare idle "eating" flavor.** Each time a zombie's ambient moan timer
  fires (every 4–12s), there is now a 1-in-25 chance it plays the existing
  `eating-brains.ogg` instead of the groan — an occasional gnawing rather
  than a moan. Replaces the moan for that opportunity (does not stack).
  `eating-brains.ogg` is no longer tied to death.

- **Audio normalization.** New files normalized to match the anchor level
  of `groan.ogg` (~−14.5 LUFS, peak-limited). `groan.ogg` and
  `eating-brains.ogg` are unchanged; `eating-brains.ogg` is intentionally
  kept softer as a subtle idle sound.

- Tuning constants (`DEATH_SOUND_CHANCE`, `EAT_SOUND_CHANCE`, and the
  existing `MOAN_MIN`/`MOAN_MAX`/`COMBAT_COOLDOWN`) are grouped at the top
  of init.lua for easy adjustment.

- **Groan overlap fix.** The groan file is played by two independent
  systems — our own ambient moan timer and mobs_redo's built-in `war_cry`
  and `random` triggers (which route through `mob_sound`). With no shared
  cooldown, a chasing zombie could fire an ambient moan and a war_cry groan
  at nearly the same instant, audibly doubling the sound. Added a shared
  per-entity `_last_groan` tracker and `GROAN_COOLDOWN` (3.0s) that all
  groan-playing paths now honor, so a zombie won't play two groans on top
  of each other regardless of which system triggers them. Hit and death
  sounds are unaffected (different files, different gates).

- **Loot system reworked into two tiers (Minecraft-style).** Previously the
  valuable drops used a `min` of 0. In mobs_redo, `min = 0` is the only way
  to flag a drop "player-kill-only," but it also lets a successful roll yield
  a count of 0 — so a rare drop could "fire" and give nothing (e.g. the tooth
  appeared to drop but produced no item ~25% of the time). Drops are now split:
    - *Common scraps* (torch, apple, leather, iron lump, steel ingot) drop on
      any death, handled by mobs_redo as before, all with `min >= 1`.
    - *Valuables* (bone, bread, tooth, gold, mese fragment/crystal, gunpowder,
      keys, book, diamond, both swords) plus currency and bags are now
      **player-kill-only**, dropped by our own code in `on_die` which checks
      `cause_of_death.puncher`. Each guarantees `min >= 1` — no more empty
      rolls. Drop CHANCES are unchanged, so rarity/balance is identical; only
      the empty-roll behaviour and the environmental-death drops are removed.
      Missing optional-mod items are skipped safely (no unknown-item errors).
  This also stops passive loot farming: zombies that die to sunlight or lava
  yield only common scraps, never valuables or money.

- **Reload-persistence fix for runtime wrappers (latent bug).** The mob_sound
  throttle and the tamed-zombie `do_attack` owner-guard are installed by
  wrapping entity methods with closures. Their "already installed" state was
  tracked with boolean flags (`_sound_patched`, `_owner_guarded`). mobs_redo
  serialises most entity fields to staticdata, so those booleans SURVIVED a
  world reload — but the wrapper functions themselves did NOT (functions
  aren't serialised). After any server restart a zombie would therefore have
  the flag set but the wrapper gone, and would never re-wrap: the hit throttle
  and groan coordination silently reverted, and pets lost the hard do_attack
  owner-guard (the per-step attack-clear still protected them, so this was
  degraded, not broken). Both now detect installation by function identity
  (comparing the live method against a stored non-persisted reference) and
  re-wrap after every reload. The stale boolean flags were removed.

- **Docs:** README drops section rewritten for the two-tier model; corrected a
  pre-existing contradiction where the taming section listed teeth at 1-in-10
  (the table said 1-in-50 — 1-in-50 is correct).

## [1.0.0] — 2026-07-02

First public release for the Adventurelands game, extending Nathan
Salapat's original Zombies mod (2020). All changes below are by
TechnoWolfTV and are released under the same MIT license as the original.

- **Surface spawn nodes** changed from cobblestone/gravel to
  `default:dirt_with_grass` (night only), eliminating basement infestations.
  Dungeon and rail corridor spawning is handled by hidden spawner nodes
  (see entries below).

- **Mossycobble ABM** dungeon spawning (interval 5s, chance 1-in-50) was
  used during development and removed entirely in favour of the spawner-node
  systems below; spawner nodes are the sole dungeon spawn mechanism in the
  released version.

- **Loot table** completely redesigned around "what a person would have been
  carrying before they became a zombie." Removed terrain materials (dirt,
  coal, clay). Added: torch (1-in-5), iron_lump (1-in-15), steel_ingot
  (1-in-25), gold_lump (1-in-75), mese_crystal_fragment (1-in-100),
  gold_ingot (1-in-150), keys:key (1-in-200), mese_crystal (1-in-250),
  book (1-in-250), diamond (1-in-300), sword_mese (1-in-1000),
  sword_diamond (1-in-1500). Removed references to maxhp, commoditymarket,
  epic, and stations mods from the original.

- **Currency drops** added as optional (requires currency mod): tiered from
  5c coins (currency:minegeld_cent_5, 1-in-3) through M$100 notes
  (currency:minegeld_100, 1-in-500). All wrapped in a
  minetest.get_modpath('currency') guard.

- **Bag drops** added as optional (requires unified_inventory):
  bag_small (1-in-100), bag_medium (1-in-500), bag_large (1-in-1000).
  Wrapped in minetest.get_modpath('unified_inventory') guard.

- **Taming** changed from fantasy_mobs:fairy_dust (1 item) to zombies:tooth
  (3 items required). In-game hint fires when fewer than 3 are held.
  Anti-theft guard prevents any player other than the registered owner
  from claiming an already-owned zombie.

- **Tamed zombie loyalty:** taming converts the zombie from mobs_redo type
  `monster` to `npc`. This is required because mobs_redo hard-codes
  monsters as untameable: monsters attack their owners (the tamed
  "must be provoked" exemption at api.lua:1701 excludes the monster type),
  cannot owner-follow (npc-only, api.lua:1884), and are flagged
  `static_save=false` at activation while wild (api.lua:2955) so the engine
  discards them on unload. Taming also explicitly restores `static_save=true`
  (mirroring mobs_redo's own feeding-tame), sets `tamed=true` (no despawn),
  `light_damage=0` (survives sunlight), clears any active attack state, and
  installs a per-entity `do_attack` override that refuses the owner as a
  target (`do_attack` is the single function all mobs_redo attack acquisition
  flows through). Owner right-clicks the pet to toggle order between follow
  and stand; npc owner-follow only ever targets the registered owner, so
  other players cannot lead or lure it. `owner_loyal=true` on the definition
  makes the pet attack whatever the owner punches; an `on_punchplayer` hook
  rallies owned zombies within 16 nodes onto anything that punches their
  owner; a `do_custom` failsafe clears the owner as a target if stale state
  ever reappears. A per-step attack-clear in `do_custom` (runs before
  `do_states`) drops the owner as a target every step as an additional
  guarantee. Pets tamed under older mod versions are auto-repaired at
  activation (type conversion, persistence flag, owner guard applied
  retroactively). All taming state is serialised by mobs_redo and survives
  world reloads and server restarts.

- **Pants skin randomizer fixed:** math.random(4) corrected to math.random(6)
  so all 6 pants variants (blue, green, brown, black, purple, none) can
  spawn. Previously purple and pants-less zombies were unreachable.

- **Sound system replaced:** independent per-entity ambient moan fires every
  4-12 seconds (random interval per zombie), driven by a `do_custom` timer
  entirely separate from mobs_redo's sound system. Combat sounds (war_cry,
  damage) throttled to once per 2.5 seconds per entity. Death sound
  (eating-brains.ogg) bypasses the throttle and always fires. Prevents a
  single zombie from layering its own sounds.

- **zombies global table localized** (was global, now local).

- **moon_phases dependency:** confirmed compatible with climate_modpack's
  `moon_phase` mod (internal name = `moon_phases`, exposes
  `moon_phases.get_phase()` returning 1-8; phase 4 = full moon). Full moon
  effect fires in `on_spawn` only — affects newly spawning `zombies:normal`,
  not ones already in the world.

- **Rail corridor zombie spawners:** self-contained placement via LBM
  `zombies:seed_corridor_spawners` (tsm_railcorridors optional_depends;
  tsm itself is unmodified). Fires as rail-containing mapblocks activate,
  `run_at_every_load=true` (idempotent via zombie_spawner group spacing
  check). Straight rail runs of >= 10 contiguous rails qualify. A
  camouflaged spawner node is embedded in the floor one node to the side of
  a mid-run rail (perpendicular to the run axis), validated as solid with air
  above. Corridor axis stored in node metadata; spawn timer searches +-6
  along the tunnel and +-1 across, producing zombies that approach from down
  the corridor. Minimum 18-node spacing between spawners (shared
  zombie_spawner group also spaces against dungeon spawners). Below y=0 only.
  Deterministic placement (PcgRandom seeded from node coordinates, 1-in-12
  gate). 8 camouflage variants: zombies:corridor_spawner (stone) and
  _sandstone, _desert_stone, _desert_sand, _silver_sandstone, _dirt,
  _gravel, _cobble. Each copies tiles/sounds/drop from the real floor node;
  not_in_creative_inventory; is_ground_content=false. Timer 12-25s, spawn
  radius 6, light <= 13, cap 8 zombies within 20 nodes, day or night.

- **Dungeonsplus room spawner** added via `dungeonsplus.register_dungeon_feature()`
  (optional_depends; registered in `minetest.register_on_mods_loaded`). 5
  camouflage variants: `zombies:dungeon_spawner` (mossycobble, original name
  preserved for world compatibility), `_cobble`, `_sandstonebrick`,
  `_desert_stone`, `_ice`. Unknown floors fall back to cobble-look. Placed on
  the center floor of dungeon rooms with ceilings, below y=0. Weight 3 in
  feature pool (~1 in 4 rooms). Timer 18-25s (~1 zombie per 21 seconds per
  room on average), spawn radius 6, light <= 10, cap 8 zombies within 20
  nodes, day or night. Dungeon spawner nodes and timer registered
  unconditionally (outside the dungeonsplus guard) so they are available to
  the retrofit LBM and manual placement regardless of whether dungeonsplus is
  installed.

- **Dungeon retrofit LBM** (`zombies:seed_dungeon_spawners`): seeds spawners
  into already-generated dungeons as mapblocks activate,
  `run_at_every_load=true` (idempotent via spacing). Triggers on
  `default:mossycobble` floor nodes (walkable, air above), below y=0.
  Deterministic 1-in-8 gate per position (PcgRandom seeded from coordinates).
  Minimum 20-node spacing via group:zombie_spawner. Replaces the mossycobble
  node in-place with `zombies:dungeon_spawner` (perfect camouflage). Covers
  cobble/mossy dungeons in ~38 biomes in existing worlds; sandstone/desert/ice
  dungeons in old terrain cannot be safely detected. Requires no optional mods.

- **Spawner reliability:** all spawner nodes self-arm via `on_construct`.
  Rearm LBM (`zombies:rearm_spawners`, nodenames=group:zombie_spawner,
  `run_at_every_load=true`) restarts any spawner whose timer is not running,
  covering crash windows and external placement tools (WorldEdit, schematics).

- **mod.conf updated:** optional_depends = farming, currency, tnt, bonemeal,
  tsm_railcorridors, dungeonsplus, unified_inventory, keys. fantasy_mobs
  removed from depends. Description updated to reflect final behaviour.
