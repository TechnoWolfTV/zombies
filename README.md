# Zombies

A Luanti mod that adds three styles of zombie to your world, built on the
**mobs_redo** API. Zombies stalk the surface at night, lurk in mapgen
dungeons and dungeonsplus rooms around the clock, and haunt rail corridors
in the dark. They can be tamed into loyal companions.

Originally by **Nathan Salapat** (2020).  
Modified and extended by **TechnoWolfTV** (2026) for the
[Adventurelands](https://github.com/TechnoWolfTV/Adventurelands) game.

This README describes current behaviour. For the full history of changes,
see [CHANGELOG.md](CHANGELOG.md).

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
  Occasionally (about 1 in 25 of these moan opportunities) a zombie makes a
  wet gnawing "eating" sound instead of a groan — a subtle bit of flavor
  rather than a moan.
- **Getting hit** — striking a zombie plays a distinct impact grunt. This
  is throttled to once per 2.5 seconds per zombie so hitting one rapidly
  doesn't stack the sound on itself.
- **Combat groans** — when a zombie's pathfinder resolves a route toward
  you it emits a groan, sharing the same 2.5-second per-zombie throttle.
- **Death** — usually silent. On death there is a 1-in-4 chance the zombie
  lets out a death cry; most of the time it dies quietly.

Sounds are sourced from `groan.ogg`, `eating-brains.ogg`, `zombies_hit.ogg`
(CC0, Under7dude), and `zombies_death.ogg` (CC0, dreggsome). See
`license.txt` for full credits. The chances and timings above are defined as
named constants near the top of `init.lua` if you want to tune them.

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

All three zombie types share the same loot, split into two tiers modelled on
how Minecraft handles mob drops:

- **Common scraps** drop on **any** death — whether you kill the zombie, it
  burns in sunlight, or it falls in lava. A zombie always leaves a little
  something behind, but nothing in this tier is worth farming passively.
- **Valuables** drop **only when a player lands the killing blow.** A zombie
  that dies to sunlight, lava, fall damage, or another mob drops none of
  these. This prevents passive loot farms — you have to earn the good stuff.

Each line rolls independently, and `chance` is 1-in-N. Every successful roll
now yields **at least the listed minimum** — there are no empty drops. (A
prior version reused a min of 0 on the valuable items; that was the mechanism
the underlying mob API uses to mark an item "player-kill-only," but it also
let successful rolls produce nothing. The two behaviours are now separated:
the player-kill gate is enforced directly, and every drop yields ≥ 1.)

### Common scraps (drop on any death)

| Item | Chance | Min | Max | Notes |
|---|---|---|---|---|
| `bonemeal:bone` | 1 in 10 | 1 | 1 | Their remains (requires bonemeal) |
| `farming:bread` | 1 in 10 | 1 | 1 | Food (requires farming mod) |
| `default:torch` | 1 in 10 | 1 | 1 | Everyone carries torches |
| `default:apple` | 1 in 10 | 1 | 1 | Food |
| `mobs:leather` | 1 in 10 | 1 | 1 | Clothing/belt |

### Valuables (player kill only)

Themed around what a person would have been carrying before they became a
zombie. None of these drop unless a player lands the kill.

| Item | Chance | Min | Max | Notes |
|---|---|---|---|---|
| `default:iron_lump` | 1 in 15 | 1 | 1 | Miner carrying ore |
| `default:steel_ingot` | 1 in 20 | 1 | 1 | Smith or trader |
| `default:gold_lump` | 1 in 75 | 1 | 1 | Prospector or lucky miner |
| `zombies:tooth` | 1 in 50 | 1 | 3 | Their tooth — taming currency |
| `default:mese_crystal_fragment` | 1 in 100 | 1 | 1 | Carried shard |
| `tnt:gunpowder` | 1 in 100 | 1 | 1 | Miner's supplies (requires tnt mod) |
| `default:gold_ingot` | 1 in 150 | 1 | 1 | Merchant or wealthy traveller |
| `keys:key` | 1 in 200 | 1 | 1 | Key-holder — what did they guard? |
| `default:mese_crystal` | 1 in 250 | 1 | 1 | Adventurer's carried gem |
| `default:book` | 1 in 250 | 1 | 1 | Scholar or scribe |
| `default:diamond` | 1 in 300 | 1 | 1 | Adventurer's treasure |
| `default:sword_mese` | 1 in 1000 | 1 | 1 | Jackpot |
| `default:sword_diamond` | 1 in 1500 | 1 | 1 | Jackpot |

Items whose mods aren't installed (bonemeal, farming, tnt) are simply skipped
— no errors, no unknown-item drops.

### Currency (requires currency mod, player kill only)

Money is in the valuables tier — only a player kill produces it, so zombies
can't be passively farmed for cash.

| Item | Value | Chance | Min | Max |
|---|---|---|---|---|
| `currency:minegeld_cent_5` | 5¢ | 1 in 3 | 1 | 5 |
| `currency:minegeld_cent_10` | 10¢ | 1 in 5 | 1 | 3 |
| `currency:minegeld_cent_25` | 25¢ | 1 in 8 | 1 | 3 |
| `currency:minegeld` | M$1 | 1 in 20 | 1 | 2 |
| `currency:minegeld_5` | M$5 | 1 in 75 | 1 | 2 |
| `currency:minegeld_10` | M$10 | 1 in 100 | 1 | 1 |
| `currency:minegeld_50` | M$50 | 1 in 250 | 1 | 1 |
| `currency:minegeld_100` | M$100 | 1 in 500 | 1 | 1 |

Currency drops are only registered if the currency mod is present at load
time. The mod works without it — no errors, no unknown item drops.

### Bags (requires unified_inventory, player kill only)

| Item | Chance | Min | Max |
|---|---|---|---|
| `unified_inventory:bag_small` | 1 in 100 | 1 | 1 |
| `unified_inventory:bag_medium` | 1 in 500 | 1 | 1 |
| `unified_inventory:bag_large` | 1 in 1000 | 1 | 1 |

Bag drops are only registered if unified_inventory is present at load time.

### Looting enchantment (optional, x_enchanting-compatible)

If you kill a zombie with a weapon that carries a **Looting** enchantment,
every drop — common scraps and valuables alike — gets a bonus chance at an
extra roll. The boost is **tiered** and, importantly, **rarity-preserving**:
looting grants an extra "lottery ticket" at each item's *own* drop chance
rather than a flat guaranteed drop, so rare items stay rare and only their
odds improve proportionally.

The extra-ticket probability follows the standard looting curve
(`level / (level + 1)`): Looting I ≈ 50%, II ≈ 67%, III ≈ 75%. Applied to the
tooth (base 1-in-50) that works out roughly to:

| Looting | Effective tooth rate |
|---|---|
| none | ~1 in 50 |
| I | ~1 in 35 |
| II | ~1 in 31 |
| III | ~1 in 30 |

A 1-in-1500 diamond sword, by contrast, only improves to about 1-in-860 at
Looting III — a real boost, but still a jackpot. Looting only ever applies on
player kills (like all the valuables), and the bonus is additive on top of the
normal drops.

This reads the enchantment level directly from the weapon's item metadata
(`is_looting`), the same field [x_enchanting](https://content.luanti.org/packages/SaKeL/x_enchanting/)
uses. **No enchanting mod is required** — with none installed the field is
simply absent and looting has no effect, with zero errors. x_enchanting is
listed only as an optional dependency for load order; the zombies mod never
calls its API.

---

## Taming

**Only `zombies:normal` can be tamed.** One-arm and crawler zombies remain
permanently hostile.

### How to tame

1. Collect **zombie teeth** (`zombies:tooth`) — they drop from all three
   zombie types at a 1-in-50 chance, 1–3 per kill, **only when you land the
   kill yourself** (teeth are in the player-kill-only tier). Expect to kill a
   couple dozen zombies before accumulating the three teeth required.
2. Hold a stack of **at least 3 teeth** in your active hand slot.
3. **Right-click a normal zombie.** It growls "Braaaaiiiiinnnnssss", becomes
   yours, and any attack in progress against you is immediately cancelled.

If you hold fewer than 3 teeth and right-click, the zombie tells you it
wants 3. Already-owned zombies tell you they have an owner and cannot be
claimed — tamed zombies are theft-proof.

### What a tamed zombie does

- **Belongs to you** permanently — ownership persists across world reloads
  and server restarts.
- **Never attacks you.**
- **Survives daylight** — tamed zombies take no sunlight damage.
- **Never despawns** — your pet stays in the world indefinitely.
- **Stands guard** where you tamed it until told to follow (see below).
- **Stops attacking you instantly** if it was mid-fight when tamed.

### Following

**Right-click your tamed zombie to toggle between Follow and Stay.** In
follow mode it shambles after you using mobs_redo's native NPC
owner-following, which only ever targets the registered owner — other
players cannot command, lead, or lure your zombie under any circumstances.
Right-click again and it stands guard where it stops. The current order
persists across world reloads.

### Loyalty and defence

- **Attacks what you attack:** punch any entity near your tamed zombie and
  it joins the fight against that target.
- **Defends you:** if anything — player or hostile mob — attacks you, your
  tamed zombies within 16 nodes turn on the attacker.
- **Never attacks you** under any circumstances.

### Survival across restarts

Tamed zombies are saved with the world. After any reload or server restart
your pet reappears where you left it, still owned, standing guard in Stay
mode — right-click to resume Follow mode. Zombies tamed under older
versions of the mod are upgraded automatically the first time they load;
no re-taming is ever needed.

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
| `keys` | Optional | `keys:key` drop (part of minetest_game) |
| `unified_inventory` | Optional | Bag drops (small, medium, large) |

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
