# Zombies

A Luanti mod that adds three styles of zombie to your world, built on the
**mobs_redo** API. Zombies stalk the surface at night, lurk in mapgen
dungeons and dungeonsplus rooms around the clock, and haunt rail corridors
in the dark. They can be tamed into loyal companions. All spawning uses
hidden, camouflaged spawner nodes — no constant ABM scanning underground.

Originally by **Nathan Salapat** (2020).  
Modified and extended by **TechnoWolfTV** (2026) for the
[Adventurelands](https://github.com/TechnoWolfTV/Adventurelands) game.

---

## Mob Types

| Mob | HP | Walk / Run | Reach | Notes |
|---|---|---|---|---|
| `zombies:normal` | 1–40 | 2 / 4 | 3 | Tameable; doubles in size on a full moon |
| `zombies:1arm` | 3–30 | 2 / 4 | 2 | Slightly tougher |
| `zombies:crawler` | 1–20 | 0.5 / 1 | 2 | Slow; low collision box |

All three share **80% armor**, **75% damage chance**, and **4 damage per
hit**. They jump, pathfind, and take lava, sunlight, and fall damage.

### Skins

Skins are procedurally composed at each world load from five independent
layers: skin tone (tan, green, ash), face (5 variants), shirt (blue,
white, rags, none), pants (blue, green, brown, black, purple, none), and
hair (4 styles, none). Layers are combined via texture modifiers, giving
16 randomised combinations. No two world sessions are guaranteed to look
the same.

---

## Combat Behaviour

All three zombie types are **monsters**: they aggro any player on sight
within 15 nodes, pathfind around obstacles, and give chase. Damage is
applied at 75% chance per swing with a reach of 2–3 nodes depending on
type. They do not despawn while a player is nearby; untamed zombies
despawn when they drift far from any player and their lifetimer expires.

---

## Sounds

Each zombie entity runs its own **independent sound system**, separate from
mobs_redo's built-in sound triggers:

- **Ambient moans** — each zombie picks a random interval between 4 and 12
  seconds and groans independently. This is per-entity and per-timer, so a
  group of zombies produces overlapping, irregular moaning rather than
  synchronised bursts. You will often hear zombies before you see them.
- **Combat groans** — when a zombie's pathfinder resolves a route toward
  you it emits a groan. These are throttled to once per 2.5 seconds per
  zombie to prevent a single chasing zombie from layering the sound on
  itself repeatedly.
- **Death** — always plays `eating-brains.ogg` on death, unthrottled,
  regardless of the combat cooldown.

---

## Full Moon

During **moon phase 4** (the full moon in an 8-phase cycle), any
`zombies:normal` that spawns does so at **double size** with a scaled
collision box. The size change fires in the mob's `on_spawn` callback, so
it only applies to zombies that first appear during the full moon — zombies
that were already in the world and survive into a full moon night remain
normal-sized. The effect resets naturally as the moon phase changes and
new zombies spawn at standard size.

Requires the **moon_phases** mod. This mod is compatible with the
`moon_phase` mod inside `climate_modpack` (internal mod name `moon_phases`,
exposes `moon_phases.get_phase()` returning 1–8).

---

## Spawning

This mod uses three distinct spawn systems. Each is independent and
targets a different habitat. All underground systems operate day and night
— light level, not time of day, governs whether spawning is suppressed.

### How spawner nodes work

Underground and rail spawning uses hidden **spawner nodes** rather than
ABM scanning. A spawner node is embedded in the terrain at placement time,
is visually identical to the floor material it replaced (camouflaged), is
not in the creative inventory, and drops its floor material if mined. Each
spawner runs a node timer that fires every 12–25 seconds (corridors) or
18–25 seconds (dungeons). On each tick it:

1. Checks the light level at its own position against the cap for its
   type. If too bright, it reschedules and does nothing.
2. Throws up to 10–16 random position attempts within 6 nodes looking for
   a walkable surface with air above (i.e. valid standing room).
3. Skips any position within 12 nodes of a connected player — zombies
   never pop into existence directly in front of you.
4. Counts nearby zombies within 20 nodes. If 8 or more are already active,
   it reschedules and does nothing.
5. Spawns a random zombie type (1arm, crawler, or normal) at the chosen
   position.
6. Restarts its own timer for another random interval.

**Counter-play:** place torches. All spawner types respect a maximum light
level. Lighting a dungeon room or corridor section above the threshold
permanently stops spawning there for as long as the light persists. Dungeon
spawners stop at light > 10; corridor spawners stop at light > 13 (higher
because corridors are already lit by torches at level 12 — only sunlight,
at level 15, exceeds 13, so surface-breached corridors go quiet in daylight
while underground ones remain active around the clock).

**Spawner reliability:** all spawner variants self-arm their timers when
placed via `on_construct`. A maintenance LBM (`zombies:rearm_spawners`)
also re-arms any spawner whose timer is not running every time its mapblock
activates — covering server crashes between placement and timer start, and
placement via external tools such as WorldEdit or schematics.

**Removing spawners:** any spawner node can be mined normally (cracky
group). It drops its floor material (e.g. mining a sandstone-look spawner
drops `default:sandstone`). Once removed, zombies stop spawning from that
location permanently unless a new spawner is placed by the relevant LBM
on a subsequent visit — which it will not be, because the spacing check
finds no node to replace.

### Surface

| Property | Value |
|---|---|
| Spawn node | `default:dirt_with_grass` |
| Light level | 0–7 |
| Height | y ≥ 0 (surface only) |
| Time of day | **Night only** |
| Chance (per node per interval) | 1 in 6000 |
| Interval | 30 seconds |
| Max per type near player | 2 |

Surface zombies are governed by mobs_redo's ABM system (not spawner
nodes). They appear at night on grassy terrain in total or near-darkness.
They cannot spawn underground, on cobblestone, on bare dirt, or indoors —
your base is safe as long as it has a roof and is not on grass. Each zombie
type (1arm, crawler, normal) has its own cap of 2 nearby, so up to 6
mixed-type zombies can be active in the same area at night.

### Dungeons — new rooms (requires dungeonsplus)

| Property | Value |
|---|---|
| Placement | Center floor of qualifying dungeon rooms |
| Frequency | ~1 in 4 rooms (weight 3 in feature pool) |
| Camouflage | Matches floor: mossy cobble, cobble, sandstone brick, desert stone, or ice |
| Light level | ≤ 10 at spawner |
| Height | y < 0 |
| Time of day | **Day or night** |
| Timer interval | 18–25 seconds (random) |
| Max zombies per spawner | 8 (within 20 nodes) |

When dungeonsplus generates a dungeon room that has a ceiling and sits
below y = 0, it rolls the zombie spawner as one of its weighted floor
features (weight 3, between forge at 4 and bare floor at 2). The spawner
is placed at the room's centre floor via VoxelManip and is camouflaged as
the floor material it replaces. Five camo variants exist:
`zombies:dungeon_spawner` (mossy cobble), `_cobble`, `_sandstonebrick`,
`_desert_stone`, `_ice`. Any other floor material falls back to the
cobble-look variant. The timer starts after the VoxelManip write via a
deferred callback, producing roughly one zombie per 21 seconds on average
per room once a player is within active range.

If dungeonsplus is not installed this system is silently skipped.

### Dungeons — existing worlds (retrofit LBM)

| Property | Value |
|---|---|
| Trigger node | `default:mossycobble` floor (walkable, air above) |
| Coverage | Cobble/mossy biome dungeons (~38 biomes) |
| Placement gate | Deterministic 1-in-8 per node position |
| Minimum spacing | 20 nodes between spawners |
| Height | y ≤ 0 |

An LBM (`zombies:seed_dungeon_spawners`, runs every load) fires when any
mapblock containing mossycobble activates. Mossycobble nodes that are
walkable with air above (i.e. dungeon floor accent blocks) pass a
deterministic 1-in-8 gate (seeded from node coordinates, so the same
positions are chosen on every world load) and are replaced in-place with
`zombies:dungeon_spawner` — the mossycobble-look variant, so camouflage is
perfect. The spacing check against the `zombie_spawner` group (shared
across all 13 spawner variants) keeps spawners at least 20 nodes apart.

This system retrofits dungeons in existing worlds the first time their
mapblocks are activated — no world regeneration needed. It requires no
optional mods. Newly generated dungeons of all five floor types receive
spawners via the dungeonsplus feature above; the retrofit covers the
cobble/mossy majority in old terrain.

**Caveat:** sandstone, desert stone, and ice dungeons in old terrain cannot
be safely detected (those materials appear commonly in the natural
landscape) and are not retrofitted. Only newly generated dungeons of those
types receive spawners.

**Player-built mossycobble floors below y = 0** also qualify. A player
constructing a mossycobble floor underground is effectively building zombie
habitat — this is considered intentional (the material is dungeon-flavoured
and requires junglegrass + cobble to craft via moreblocks).

### Rail Corridors (requires tsm_railcorridors)

| Property | Value |
|---|---|
| Qualifying corridor | ≥ 10 contiguous rails in a straight line |
| Placement | Floor node beside a mid-run rail |
| Minimum spacing | 18 nodes between spawners |
| Camouflage | Matches floor: stone, sandstone, desert stone, desert sand, silver sandstone, dirt, gravel, or cobble |
| Spawn radius | 6 nodes along the corridor axis |
| Light level | ≤ 13 at spawner |
| Height | y ≤ 0 |
| Time of day | **Day or night** |
| Timer interval | 12–25 seconds (random) |
| Max zombies per spawner | 8 (within 20 nodes) |

An LBM (`zombies:seed_corridor_spawners`, runs every load) fires when any
rail-containing mapblock activates. Each rail node passes a deterministic
1-in-12 gate; passing nodes are then checked for a straight run of at
least 10 contiguous rails along either axis, filtering out cart side-rails,
dead-end stubs, and crossing fragments. The LBM embeds a camouflaged
spawner in the **floor node one step to the side of the rail** (perpendicular
to the run axis), validated as solid with air above so it always sits inside
the corridor cavity rather than poking into a wall.

Eight camo variants exist (`zombies:corridor_spawner` for stone and one
each for sandstone, desert_stone, desert_sand, silver_sandstone, dirt,
gravel, cobble). Any other floor falls back to stone-look. The corridor's
axis is stored in node metadata at placement; the spawn timer uses this
to search for positions **along the tunnel** (±6 along, ±1 across) rather
than in all directions, so zombies materialise down the corridor and
approach the player rather than failing on walls.

The LBM is idempotent: the spacing check against `group:zombie_spawner`
(shared with dungeon spawners) means once a spawner exists nearby, all
subsequent LBM passes for that area are instant no-ops. Existing worlds
are retrofitted as corridor mapblocks activate on first player visit.

Because tsm_railcorridors can carve an entire corridor system from a single
chunk's generation event — spilling rails across many neighbouring chunks —
a generation-time scan would miss most of the system. The LBM approach
catches every rail block when it first becomes active, regardless of which
chunk triggered generation.

Placement is logged to `debug.txt` as:
`[zombies] corridor spawner (zombies:corridor_spawner_sandstone) placed at (x,y,z)`

If tsm_railcorridors is not installed this system is silently skipped.

---

## Drops

All three zombie types share the same loot table. Each line rolls
independently on every kill. `chance` is 1-in-N; a `min` of 0 means even
a successful roll can yield nothing.

### Always available

| Item | Chance | Min | Max | Notes |
|---|---|---|---|---|
| `default:dirt` | 1 in 2 | 3 | 5 | Very common |
| `bonemeal:bone` | 1 in 3 | 0 | 10 | Common (requires bonemeal mod) |
| `mobs:leather` | 1 in 4 | 1 | 3 | Common |
| `default:coal_lump` | 1 in 5 | 0 | 1 | Common |
| `default:apple` | 1 in 6 | 2 | 5 | Common |
| `farming:bread` | 1 in 7 | 0 | 2 | Uncommon (requires farming mod) |
| `default:clay_lump` | 1 in 10 | 1 | 4 | Uncommon |
| `zombies:tooth` | 1 in 10 | 0 | 3 | Uncommon — taming currency |
| `default:mese_crystal_fragment` | 1 in 100 | 1 | 2 | Very rare |
| `tnt:gunpowder` | 1 in 100 | 0 | 1 | Very rare (requires tnt mod) |
| `default:diamond` | 1 in 300 | 1 | 1 | Extremely rare |
| `default:sword_mese` | 1 in 1000 | 0 | 1 | Jackpot |
| `default:sword_diamond` | 1 in 1500 | 1 | 1 | Jackpot |
| `default:diamondblock` | 1 in 5000 | 1 | 1 | Legendary |

### Currency (requires currency mod)

| Item | Value | Chance | Min | Max |
|---|---|---|---|---|
| `currency:minegeld_cent_5` | 5¢ | 1 in 3 | 1 | 5 |
| `currency:minegeld_cent_10` | 10¢ | 1 in 5 | 1 | 3 |
| `currency:minegeld_cent_25` | 25¢ | 1 in 8 | 1 | 2 |
| `currency:minegeld` | M$1 | 1 in 20 | 1 | 3 |
| `currency:minegeld_5` | M$5 | 1 in 75 | 1 | 2 |
| `currency:minegeld_10` | M$10 | 1 in 200 | 1 | 1 |
| `currency:minegeld_50` | M$50 | 1 in 500 | 1 | 1 |
| `currency:minegeld_100` | M$100 | 1 in 2000 | 1 | 1 |

Currency drops are only registered if the currency mod is present at load
time. The mod works without it — no errors, no unknown item drops.

---

## Taming

**Only `zombies:normal` can be tamed.** One-arm and crawler zombies remain
permanently hostile.

### How to tame

1. Collect **zombie teeth** (`zombies:tooth`) — they drop from all three
   zombie types at 1-in-10 chance, 0–3 per kill. Expect to kill a dozen
   or two before accumulating the three teeth required.
2. Hold a stack of **at least 3 teeth** in your active hand slot.
3. **Right-click a normal zombie.** It growls "Braaaaiiiiinnnnssss", becomes
   yours, and any attack in progress against you is immediately cancelled.

If you hold fewer than 3 teeth and right-click, the zombie tells you it
wants 3. Already-owned zombies tell you they have an owner and cannot be
claimed — tamed zombies are theft-proof.

### What changes at taming

- **Ownership:** `self.owner` is set to your player name. This persists
  across world reloads and server restarts — the owner field is serialised
  into the mob's staticdata and restored on activation.
- **Becomes an NPC:** the zombie's mobs_redo type changes from `monster` to
  `npc`. This is essential: mobs_redo hard-codes monsters as untameable —
  monsters attack their owners (the tamed "must be provoked" exemption
  excludes the monster type), cannot owner-follow (an NPC-only mechanic),
  and are marked non-persistent while wild. The type change fixes all of
  this at the source and persists across restarts.
- **Engine persistence restored:** while wild, mobs_redo flags monster
  entities `static_save = false` so the engine discards them on unload.
  Taming explicitly restores `static_save = true`, so your pet is saved
  with the world and reappears exactly where you left it after any reload
  or server restart.
- **No despawn:** `self.tamed = true` prevents mobs_redo's lifetimer and
  far-mob cleanup from ever removing the zombie.
- **Sunlight immunity:** `light_damage` is set to 0. The zombie survives
  outdoors in daylight indefinitely.
- **Standing order:** the zombie enters `order = stand`, halting in place.
- **Aggro cleared:** any active attack state and pathfinding target are
  reset immediately so the zombie does not finish a swing at you after taming.

Zombies tamed under older versions of this mod are automatically repaired
the moment they activate: the type conversion, persistence flag, and owner
protections are applied retroactively — no re-taming required.

### Following

**Right-click your tamed zombie to toggle between Follow and Stay.** In
follow mode it shambles after you using mobs_redo's native NPC
owner-following, which only ever targets the registered owner — other
players cannot command, lead, or lure your zombie under any circumstances.
Right-click again and it stands guard where it stops. The current order
persists across world reloads.

### Loyalty and defence

Tamed zombies obey two loyalty rules:

1. **Attack what the owner attacks:** `owner_loyal = true` is set on the
   mob definition. In mobs_redo this means when you punch any entity near
   your tamed zombie, it joins the fight against that entity. This is
   mobs_redo's native mechanic, so it works reliably against all entity
   types.

2. **Defend the owner:** an `on_punchplayer` hook fires whenever any player
   is punched. If the punched player has tamed zombies within 16 nodes,
   those zombies immediately attack the entity that threw the punch. This
   covers defence against both other players and hostile mobs.

3. **Never attack the owner:** three layers guarantee this. First,
   mobs_redo's attack acquisition loop already skips any player who is the
   mob's registered owner. Second, taming installs a per-entity `do_attack`
   override — `do_attack` is the single function every attack acquisition
   in mobs_redo funnels through, so refusing the owner there is an absolute
   guarantee no code path can bypass. Third, a per-step failsafe in
   `do_custom` clears the attack target if the owner ever appears as one.
   The override is reinstalled automatically when a previously tamed zombie
   loads from a save. Your tamed zombie will never hurt you.

### Survival across restarts

mobs_redo serialises the full entity state to `staticdata` on unload. The
zombie's `owner`, `tamed`, `order`, `follow`, and `light_damage` fields are
all plain Lua values and are automatically included in this serialisation —
no special handling is required. On reload your zombie reappears at the
same position, still owned, still tamed, standing idle (mobs_redo resets
`state` to `stand` and clears `attack`/`following` on unload, which is
correct — the zombie stands guard until you pull out a tooth again).

---

## Dependencies

| Mod | Type | Purpose |
|---|---|---|
| `default` | Required | Core nodes, items, and dungeon floor materials |
| `mobs` (mobs_redo) | Required | Mob API, spawning, taming, serialisation |
| `moon_phases` | Required | Full moon phase detection for giant zombie |
| `farming` | Optional | `farming:bread` drop |
| `currency` | Optional | Tiered currency drop table |
| `tnt` | Optional | `tnt:gunpowder` drop |
| `bonemeal` | Optional | `bonemeal:bone` drop |
| `tsm_railcorridors` | Optional | Rail corridor LBM spawner system |
| `dungeonsplus` | Optional | Dungeon room spawner feature integration |

All optional dependencies degrade gracefully. If a mod is absent, its
associated features are silently skipped at load time — no errors are
produced and the rest of the mod functions normally.

---

## Technical Notes

### Spawner node groups

All 13 spawner variants (8 corridor + 5 dungeon) share the group
`zombie_spawner = 1`. The spacing checks for both LBMs query
`group:zombie_spawner`, so corridor and dungeon spawners mutually avoid
each other as well as their own kind.

### Registered nodes

This mod registers 13 hidden spawner nodes beyond the standard mob and
item registrations. All are in `not_in_creative_inventory` and have
`is_ground_content = false` (preventing cave carving or rail overwrites).

### LBM names

- `zombies:seed_corridor_spawners` — corridor spawner placement
- `zombies:seed_dungeon_spawners` — dungeon retrofit placement
- `zombies:rearm_spawners` — timer maintenance for all spawner variants

### Logging

On load, the mod logs its active systems:
`[zombies] mod loaded: surface ABM + dungeon/corridor spawner nodes active[, rail corridor spawner active][, dungeonsplus spawner feature active]`

Spawner placements are logged at action level:
`[zombies] corridor spawner (zombies:corridor_spawner_sandstone) placed at (x,y,z)`
`[zombies] dungeon spawner (retrofit) placed at (x,y,z)`
`[zombies] dungeonsplus Zombie Spawner feature registered / FAILED to register`

---

## License

Code: MIT  
Media: CC BY-SA 4.0  
Copyright 2020 Nathan Salapat  
Modifications 2026 TechnoWolfTV — see `license.txt` for full details.
