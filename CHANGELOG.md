# Changelog

All notable changes to the Zombies mod are documented here. This file is
the authoritative record of what has changed; the README describes current
behaviour only.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.0] — 2026-07-02

First public release for the Adventurelands game, extending Nathan
Salapat's original Zombies mod (2020). All changes below are by
TechnoWolfTV and are released under the same MIT license as the original.

- Surface spawn nodes changed from cobblestone/gravel to
    default:dirt_with_grass (night only), eliminating basement infestations.
    Dungeon and rail corridor spawning is handled by hidden spawner nodes
    (see entries below).

  - Mossycobble ABM dungeon spawning (interval 5s, chance 1-in-50) was
    used during development and later removed entirely in favour of the
    spawner-node systems below; spawner nodes are the sole dungeon spawn
    mechanism in the released version.

  - All drops replaced with items verified present in Adventurelands.
    Removed references to maxhp, commoditymarket, epic, and stations mods.

  - Currency drops added as optional (requires currency mod): tiered from
    5c coins (currency:minegeld_cent_5, 1-in-3, 1-5) through M$100 notes
    (currency:minegeld_100, 1-in-2000, 1). All wrapped in a
    minetest.get_modpath('currency') guard so the mod works without the
    currency mod installed.

  - Diamond drops added: default:diamond (1-in-300), default:sword_diamond
    (1-in-1500), default:diamondblock (1-in-5000, legendary jackpot).

  - Taming changed from fantasy_mobs:fairy_dust (1 item) to zombies:tooth
    (3 items required). In-game hint fires when fewer than 3 are held.
    Anti-theft guard prevents any player other than the registered owner
    from claiming an already-owned zombie.

  - Tamed zombie loyalty: taming converts the zombie from mobs_redo type
    'monster' to 'npc'. This is required because mobs_redo hard-codes
    monsters as untameable: monsters attack their owners (the tamed
    'must be provoked' exemption at api.lua:1701 excludes the monster
    type), cannot owner-follow (npc-only, api.lua:1884), and are flagged
    static_save=false at activation while wild (api.lua:2955) so the
    engine discards them on unload. Taming also explicitly restores
    static_save=true (mirroring mobs_redo's own feeding-tame), sets
    tamed=true (no despawn), light_damage=0 (survives sunlight), clears
    any active attack state, and installs a per-entity do_attack override
    that refuses the owner as a target (do_attack is the single function
    all mobs_redo attack acquisition flows through). Owner right-clicks
    the pet to toggle order between follow and stand; npc owner-follow
    only ever targets the registered owner, so other players cannot lead
    or lure it. owner_loyal=true on the definition makes the pet attack
    whatever the owner punches; an on_punchplayer hook rallies owned
    zombies within 16 nodes onto anything that punches their owner; a
    do_custom failsafe clears the owner as a target if stale state ever
    reappears. Pets tamed under older mod versions are auto-repaired at
    activation (type conversion, persistence flag, owner guard applied
    retroactively). All taming state is serialised by mobs_redo and
    survives world reloads and server restarts.

  - Pants skin randomizer fixed: math.random(4) corrected to math.random(6)
    so all 6 pants variants (blue, green, brown, black, purple, none) can
    spawn. Previously purple and pants-less zombies were unreachable.

  - Sound system replaced: independent per-entity ambient moan fires every
    4-12 seconds (random interval per zombie), driven by a do_custom timer
    entirely separate from mobs_redo's sound system. Combat sounds
    (war_cry, damage) throttled to once per 2.5 seconds per entity.
    Death sound (eating-brains.ogg) bypasses the throttle and always fires.
    Prevents a single zombie from layering its own sounds.

  - zombies global table localized (was global, now local).

  - moon_phases dependency: confirmed compatible with climate_modpack's
    moon_phase mod (internal name = moon_phases, exposes
    moon_phases.get_phase() returning 1-8; phase 4 = full moon).
    Full moon effect fires in on_spawn only -- affects newly spawning
    zombies:normal, not ones already in the world.

  - Rail corridor zombie spawners: self-contained placement via LBM
    zombies:seed_corridor_spawners (tsm_railcorridors optional_depends;
    tsm itself is unmodified). Fires as rail-containing mapblocks activate,
    run_at_every_load=true (idempotent via zombie_spawner group spacing
    check). Straight rail runs of >= 10 contiguous rails qualify. A
    camouflaged spawner node is embedded in the floor one node to the side
    of a mid-run rail (perpendicular to the run axis), validated as solid
    with air above. Corridor axis stored in node metadata; spawn timer
    searches +-6 along the tunnel and +-1 across, producing zombies that
    approach from down the corridor. Minimum 18-node spacing between
    spawners (shared zombie_spawner group also spaces against dungeon
    spawners). Below y=0 only. Deterministic placement (PcgRandom seeded
    from node coordinates, 1-in-12 gate). 8 camouflage variants:
    zombies:corridor_spawner (stone) and _sandstone, _desert_stone,
    _desert_sand, _silver_sandstone, _dirt, _gravel, _cobble. Each copies
    tiles/sounds/drop from the real floor node; not_in_creative_inventory;
    is_ground_content=false. Timer 12-25s, spawn radius 6, light <= 13,
    cap 8 zombies within 20 nodes, day or night.

  - Dungeonsplus room spawner added via dungeonsplus.register_dungeon_feature()
    (optional_depends; registered in minetest.register_on_mods_loaded).
    5 camouflage variants: zombies:dungeon_spawner (mossycobble, original
    name preserved for world compatibility), _cobble, _sandstonebrick,
    _desert_stone, _ice. Unknown floors fall back to cobble-look. Placed
    on the center floor of dungeon rooms with ceilings, below y=0. Weight
    3 in feature pool (~1 in 4 rooms). Timer 18-25s (~1 zombie per 21
    seconds per room on average), spawn radius 6, light <= 10, cap 8
    zombies within 20 nodes, day or night. Dungeon spawner nodes and timer
    registered unconditionally (outside the dungeonsplus guard) so they
    are available to the retrofit LBM and manual placement regardless of
    whether dungeonsplus is installed.

  - Dungeon retrofit LBM (zombies:seed_dungeon_spawners): seeds spawners
    into already-generated dungeons as mapblocks activate,
    run_at_every_load=true (idempotent via spacing). Triggers on
    default:mossycobble floor nodes (walkable, air above), below y=0.
    Deterministic 1-in-8 gate per position (PcgRandom seeded from
    coordinates). Minimum 20-node spacing via group:zombie_spawner.
    Replaces the mossycobble node in-place with zombies:dungeon_spawner
    (perfect camouflage). Covers cobble/mossy dungeons in ~38 biomes in
    existing worlds; sandstone/desert/ice dungeons in old terrain cannot
    be safely detected. Requires no optional mods.

  - Spawner reliability: all spawner nodes self-arm via on_construct.
    Rearm LBM (zombies:rearm_spawners, nodenames=group:zombie_spawner,
    run_at_every_load=true) restarts any spawner whose timer is not
    running, covering crash windows and external placement tools
    (WorldEdit, schematics).

  - mod.conf updated: optional_depends = farming, currency, tnt, bonemeal,
    tsm_railcorridors, dungeonsplus. fantasy_mobs removed from depends.
    Description updated to reflect final behaviour.
