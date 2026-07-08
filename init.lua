local zombies = {
   skins = {}
}

minetest.register_craftitem('zombies:tooth', {
   description = 'Zombie Tooth',
   inventory_image = 'zombies_tooth.png',
   groups = {general_relic=-10}
})

--Skin gen
local skin_base = {'zombies_skin-tan.png', 'zombies_skin-green.png', 'zombies_skin-ash.png'}
local hair_base = {'zombies_hair-1.png', 'zombies_hair-2.png', 'zombies_hair-3.png', 'zombies_hair-4.png', 'zombies_blank.png'}
local shirt_base = {'zombies_shirt-blue.png', 'zombies_shirt-white.png', 'zombies_shirt-rags.png', 'zombies_blank.png'}
local pants_base = {'zombies_pants-blue.png', 'zombies_pants-green.png', 'zombies_pants-brown.png', 'zombies_pants-black.png', 'zombies_pants-purple.png', 'zombies_blank.png'}
local face_base = {'zombies_face-1.png', 'zombies_face-2.png', 'zombies_face-3.png', 'zombies_face-4.png', 'zombies_face-5.png'}

for i = 1, 16 do
   table.insert(zombies.skins, {skin_base[math.random(3)]..'^'..face_base[math.random(5)]..'^'..shirt_base[math.random(4)]..'^'..pants_base[math.random(6)]..'^'..hair_base[math.random(5)]})
end

-- LOOT SYSTEM
-- ============================================================================
-- Two kinds of drops:
--
--   inventory (below)          -- ordinary drops. Handled by mobs_redo's own
--                                 drop system. These can drop on ANY death.
--                                 Every entry has min >= 1 so a successful
--                                 roll always yields at least one item.
--
--   player_only_drops (below)  -- valuable/special drops. Handled by our own
--                                 code in zombie_on_die so we can guarantee
--                                 BOTH: (a) they ONLY drop when a player lands
--                                 the kill (never from lava, sunlight, fall,
--                                 or other zombies), and (b) a successful roll
--                                 always yields at least one (never zero).
--
-- WHY THE SPLIT: mobs_redo's built-in drop table has a quirk — the ONLY way to
-- mark an item "player-kill-only" is to set its min to 0, but min=0 also means
-- a successful roll can produce a count of 0 (a drop that gives nothing). The
-- original Zombies mod used min=0 on its valuable items (tooth, bone, etc.)
-- specifically to get the player-kill gate, and inherited the empty-roll side
-- effect unintentionally. We separate the two concerns: gated items live in
-- player_only_drops and get both guarantees; the empty-roll behavior is gone.
-- Drop CHANCES are unchanged from before, so rarity/balance is preserved.

-- Common "scrap" drops — the rotten-flesh tier. These can drop on ANY death
-- (player kill, sunlight, lava, fall) so a zombie always leaves a little
-- something behind, but nothing here is valuable enough to farm passively.
-- Every entry has min >= 1, so a successful roll never yields zero.
local inventory = {
   {name = 'bonemeal:bone',          chance = 10,   min = 1, max = 1},
   {name = 'farming:bread',          chance = 10,   min = 1, max = 1},
   {name = 'default:torch',          chance = 10,   min = 1, max = 1},
   {name = 'default:apple',          chance = 10,   min = 1, max = 1},
   {name = 'mobs:leather',           chance = 10,   min = 1, max = 1},
}

-- Player-kill-only drops — the valuable tier. Like Minecraft's rare drops,
-- these appear ONLY when a player lands the killing blow, never from
-- environmental deaths, so zombies can't be passively farmed for anything
-- worthwhile. Enforced in code (zombie_on_die). All have min >= 1, so a
-- successful roll always yields at least one item (no phantom zero drops).
-- Drop CHANCES are unchanged from the previous version — rarity is preserved;
-- the only change is WHICH deaths qualify and the removal of empty rolls.
local player_only_drops = {
   {name = 'default:iron_lump',      chance = 15,   min = 1, max = 1},
   {name = 'default:steel_ingot',    chance = 20,   min = 1, max = 1},
   {name = 'default:gold_lump',      chance = 75,   min = 1, max = 1},
   {name = 'zombies:tooth',          chance = 50,   min = 1, max = 3},
   {name = 'default:mese_crystal_fragment', chance = 100,  min = 1, max = 1},
   {name = 'tnt:gunpowder',          chance = 100,  min = 1, max = 1},
   {name = 'default:gold_ingot',     chance = 150,  min = 1, max = 1},
   {name = 'keys:key',               chance = 200,  min = 1, max = 1},
   {name = 'default:mese_crystal',   chance = 250,  min = 1, max = 1},
   {name = 'default:book',           chance = 250,  min = 1, max = 1},
   {name = 'default:diamond',        chance = 300,  min = 1, max = 1},
   {name = 'default:sword_mese',     chance = 1000, min = 1, max = 1},
   {name = 'default:sword_diamond',  chance = 1500, min = 1, max = 1},
}

-- Currency drops are optional: only added if the currency mod is installed.
-- Routed through player_only_drops so money is never farmable by waiting for
-- zombies to die to sunlight/lava — you must earn the kill.
if minetest.get_modpath('currency') then
   local currency_drops = {
      {name = 'currency:minegeld_cent_5',  chance = 3,    min = 1, max = 5},
      {name = 'currency:minegeld_cent_10', chance = 5,    min = 1, max = 3},
      {name = 'currency:minegeld_cent_25', chance = 8,    min = 1, max = 3},
      {name = 'currency:minegeld',         chance = 20,   min = 1, max = 2},
      {name = 'currency:minegeld_5',       chance = 75,   min = 1, max = 2},
      {name = 'currency:minegeld_10',      chance = 100,  min = 1, max = 1},
      {name = 'currency:minegeld_50',      chance = 250,  min = 1, max = 1},
      {name = 'currency:minegeld_100',     chance = 500,  min = 1, max = 1},
   }
   for _, drop in ipairs(currency_drops) do
      table.insert(player_only_drops, drop)
   end
end

-- Bag drops: only added if unified_inventory is installed. Also player-kill-only.
if minetest.get_modpath('unified_inventory') then
   local bag_drops = {
      {name = 'unified_inventory:bag_small',  chance = 100,  min = 1, max = 1},
      {name = 'unified_inventory:bag_medium', chance = 500,  min = 1, max = 1},
      {name = 'unified_inventory:bag_large',  chance = 1000, min = 1, max = 1},
   }
   for _, drop in ipairs(bag_drops) do
      table.insert(player_only_drops, drop)
   end
end

local noise = {
   distance = 10,
   random = 'groan',
   war_cry = 'groan',
   damage = 'zombies_hit',
   -- NOTE: no `death` key here on purpose. Option B: the death sound is
   -- fired manually from on_die at DEATH_SOUND_CHANCE so it plays only
   -- occasionally rather than on every death. See DEATH_SOUND_* below.
}

-- Ambient moan fires every MOAN_MIN to MOAN_MAX seconds per zombie (random)
local MOAN_MIN = 4
local MOAN_MAX = 12
-- War cry / damage sounds are throttled to at most once per COMBAT_COOLDOWN seconds
local COMBAT_COOLDOWN = 2.5
-- The groan is played by two independent systems: our own ambient moan timer
-- (below) AND mobs_redo's built-in war_cry/random triggers (which route through
-- mob_sound). Without coordination those can fire the same groan file at the
-- same instant and audibly double up. GROAN_COOLDOWN is a shared minimum gap
-- between ANY two groans from one zombie, tracked in _last_groan, so the two
-- systems can't stack on each other. Set a touch under MOAN_MIN so it never
-- suppresses a normally-scheduled ambient moan, only true near-simultaneous overlaps.
local GROAN_COOLDOWN = 3.0
-- Option B death sound: instead of playing on every death, the death cry
-- plays only occasionally. Rolled once per death in on_die.
local DEATH_SOUND = 'zombies_death'
local DEATH_SOUND_CHANCE = 4        -- 1-in-4 (25%) chance to play on death
-- Idle "eating" flavor: each time the ambient moan timer fires, there is a
-- small chance the zombie plays the eating-brains sound INSTEAD of the groan.
local EAT_SOUND = 'eating-brains'
local EAT_SOUND_CHANCE = 25         -- 1-in-25 per moan opportunity

-- Installs a per-entity do_attack override that refuses the owner as a
-- target. do_attack is the single function all attack acquisition in
-- mobs_redo funnels through, so this is a hard guarantee the zombie can
-- never attack its owner, regardless of state, save data, or timing.
-- Like the mob_sound wrapper, we detect installation by function identity
-- rather than a persisted boolean: the override is a function (not saved to
-- staticdata), so after a world reload the engine restores the unwrapped
-- do_attack and we must reinstall. A stored reference lets us tell whether
-- the live do_attack is still ours; if not, we (re)wrap.
local function zombie_guard_owner(self)
   if self.do_attack == self._zombie_attack_guard then return end
   local original_do_attack = self.do_attack
   local guard
   guard = function(s, target, force)
      if target and target.get_player_name then
         local ok, tname = pcall(function() return target:get_player_name() end)
         if ok and tname == s.owner and s.owner ~= '' then
            return
         end
      end
      return original_do_attack(s, target, force)
   end
   self.do_attack = guard
   self._zombie_attack_guard = guard
end

-- Sentinel marker for our wrapped mob_sound. We cannot rely on a persisted
-- boolean flag to know whether the wrapper is installed: mobs_redo serializes
-- most entity fields to staticdata, so a flag like _sound_patched=true SURVIVES
-- a world reload -- but the wrapper function itself does NOT (functions aren't
-- serialized). That mismatch would leave a reloaded zombie with the flag set
-- but the wrapper gone, so it would never re-wrap and would silently lose the
-- hit throttle and groan coordination after every restart. Instead we detect
-- the wrapper by identity: we keep a per-entity reference to the exact wrapper
-- we installed (itself a function, so it is NOT serialized and vanishes on
-- reload alongside the wrapper). Whenever the live mob_sound isn't that stored
-- reference -- which is exactly the fresh-spawn and post-reload case -- we
-- (re)wrap. This can never double-wrap: original_mob_sound always captures the
-- current unwrapped method at wrap time.
local function make_sound_throttle()
   return function(self, dtime)
      -- (Re)install the mob_sound wrapper if it isn't currently ours. On first
      -- run self._zombie_sound_wrapper is nil; after a reload the engine has
      -- restored the unwrapped class method, so our stored wrapper ~= the live
      -- one and we re-wrap. Timers are (re)seeded only when actually wrapping.
      if self.mob_sound ~= self._zombie_sound_wrapper then
         -- seed timers if this is a fresh entity (they may already carry
         -- sensible values restored from staticdata after a reload; only
         -- initialize the ones that are missing so we don't reset mid-cycle).
         self._combat_timer = self._combat_timer or 0
         self._moan_timer = self._moan_timer or math.random(MOAN_MIN, MOAN_MAX)
         self._last_groan = self._last_groan or 0

         local original_mob_sound = self.mob_sound
         local wrapper
         wrapper = function(s, sound)
            if not sound then return end
            local name = type(sound) == 'string' and sound or sound.name
            -- Groan coordination: war_cry and mobs_redo's built-in random
            -- sound both use the groan file and arrive through here. If our
            -- ambient moan timer (or a previous groan) played too recently,
            -- swallow this one so groans never stack. Tracked shared with the
            -- ambient timer via _last_groan.
            if name == 'groan' then
               if s._last_groan and s._last_groan < GROAN_COOLDOWN then
                  return
               end
               original_mob_sound(s, sound)
               s._last_groan = 0
               return
            end
            -- Non-groan combat sounds (damage/hit) throttled by COMBAT_COOLDOWN
            -- so striking a zombie repeatedly doesn't machine-gun the hit sound.
            -- The death sound is NOT handled here; Option B plays it directly
            -- from on_die at DEATH_SOUND_CHANCE.
            if s._combat_timer and s._combat_timer <= 0 then
               original_mob_sound(s, sound)
               s._combat_timer = COMBAT_COOLDOWN
            end
         end
         self.mob_sound = wrapper
         self._zombie_sound_wrapper = wrapper
      end

      -- tick combat cooldown
      if self._combat_timer and self._combat_timer > 0 then
         self._combat_timer = self._combat_timer - dtime
      end
      -- tick groan cooldown (shared by ambient moan + mob_sound groans)
      if self._last_groan then
         self._last_groan = self._last_groan + dtime
      end

      -- Tamed-zombie loyalty upkeep (runs every step for owned zombies):
      -- only follow the owner (strangers holding teeth cannot lure it away),
      -- and NEVER hold the owner as an attack target under any circumstance.
      if self.owner and self.owner ~= '' then
         -- Ensure the do_attack owner-guard is installed (covers zombies
         -- tamed under older versions, loaded fresh from staticdata, or
         -- reloaded after a restart). zombie_guard_owner is idempotent: it
         -- checks whether the live do_attack is still ours and only re-wraps
         -- if not, so calling it every step for owned zombies is safe.
         zombie_guard_owner(self)
         -- Repair pets tamed under older versions: convert to npc and
         -- restore engine persistence so they stop attacking the owner,
         -- can follow, and survive restarts.
         if self.type == 'monster' then
            self.type = 'npc'
            self.tamed = true
            self.object:set_properties({static_save = true})
            self.static_save = true
         end
         -- Every step: if the current attack target IS the owner, drop it.
         -- This is the most aggressive possible owner-protection: mobs_redo's
         -- do_states re-acquires targets each step, so we must counter-clear
         -- each step too. This runs before do_states in the step order.
         if self.attack then
            local atk = self.attack
            local ok, aname = pcall(function()
               if atk.get_player_name then return atk:get_player_name() end
               return ''
            end)
            if not ok or aname == self.owner then
               self.attack = nil
               self.state = 'stand'
               self.v_start = false
            end
         end
         if self.following then
            local ok, fname = pcall(function()
               return self.following.get_player_name and self.following:get_player_name()
            end)
            if not ok or (fname and fname ~= self.owner) then
               self.following = nil
            end
         end
         -- If the current attack target is the owner, drop it and reset to
         -- standing. Wrapped in pcall so a stale/invalid ObjectRef can't error.
      end

      -- ambient moan timer: fires independently of combat sounds
      if self._moan_timer then
         self._moan_timer = self._moan_timer - dtime
         if self._moan_timer <= 0 then
            -- Usually a groan; occasionally (1-in-EAT_SOUND_CHANCE) the
            -- zombie is heard gnawing instead. The eating sound replaces
            -- the groan for that opportunity rather than stacking on top.
            local ambient = 'groan'
            if math.random(EAT_SOUND_CHANCE) == 1 then
               ambient = EAT_SOUND
            end
            -- For a groan, honor the shared cooldown so we don't stack on a
            -- war_cry/random groan that just played via mob_sound. If a groan
            -- played too recently, skip this ambient one (it'll come back on
            -- the next interval). Eating-brains is exempt: different file, rare.
            local play = true
            if ambient == 'groan' then
               if self._last_groan and self._last_groan < GROAN_COOLDOWN then
                  play = false
               end
            end
            if play then
               minetest.sound_play(ambient, {
                  object = self.object,
                  max_hear_distance = noise.distance,
                  pitch = 1.0 + math.random(-10, 10) * 0.005,
               }, true)
               if ambient == 'groan' then
                  self._last_groan = 0
               end
            end
            self._moan_timer = math.random(MOAN_MIN, MOAN_MAX)
         end
      end
   end
end

-- Spawn a dropped item stack at pos, matching how mobs_redo tosses drops
-- (small random horizontal nudge + upward pop) so our custom drops look
-- identical to the engine's.
local function zombie_spawn_drop(pos, name, count)
   if count < 1 then return end
   -- Skip unknown items so a missing optional mod can't error (mirrors the
   -- way mobs_redo silently tolerates unknown drops).
   if not minetest.registered_items[name] then return end
   local obj = minetest.add_item(pos, ItemStack(name .. ' ' .. count))
   if obj then
      obj:set_velocity({
         x = math.random() - 0.5,
         y = 5,
         z = math.random() - 0.5,
      })
   end
end

-- LOOTING SUPPORT (x_enchanting-compatible, no hard dependency)
-- ----------------------------------------------------------------------------
-- x_enchanting stores the looting enchant level as a float `is_looting` on the
-- weapon's ITEM META, and only hooks entities named mobs_animal:/mobs_monster:/
-- animalia: -- so our zombies:* mobs are ignored by it. We implement looting
-- ourselves, reading the SAME meta key so behaviour matches the rest of the
-- world. Because it's just a number on the item, no x_enchanting API call is
-- needed: with no enchanting mod installed the meta is simply 0 and looting is
-- a no-op. x_enchanting is therefore an OPTIONAL dependency (load-order only) --
-- nothing here breaks without it.
--
-- Model (rarity-preserving, tiered): looting grants an EXTRA roll at each
-- item's OWN drop chance -- an additional "lottery ticket" at the same rarity,
-- not a free win. With probability looting/(looting+1) (L1=50%, L2~67%, L3=75%)
-- the item gets one extra roll at its normal 1-in-chance gate. A rare item's
-- bonus therefore stays rare (a 1/1000 sword only rises to ~1/570 at L3), while
-- common items improve more in absolute terms. Effect is additive on top of the
-- base drop and only ever runs on player kills. No-op without looting.
-- max_drop_level (from the weapon, usually 1) scales the COUNT of a bonus that
-- lands, matching x_enchanting's use of the same factor.

-- Read the looting level and max_drop_level from a puncher's wielded item.
-- Returns looting (number, 0 if none) and max_drop_level (number, >=1).
local function zombie_get_looting(puncher)
   if not puncher or type(puncher) ~= 'userdata' or not puncher.get_wielded_item then
      return 0, 1
   end
   local ok, stack = pcall(function() return puncher:get_wielded_item() end)
   if not ok or not stack then return 0, 1 end
   local looting = 0
   local meta = stack:get_meta()
   if meta then
      -- get_float returns 0 for an unset key, so this is safe with or without
      -- x_enchanting installed.
      looting = meta:get_float('is_looting') or 0
   end
   if looting < 0 then looting = 0 end
   -- max_drop_level scales the bonus count, exactly as x_enchanting does.
   -- Default to 1 (no scaling) if the tool doesn't define it.
   local mdl = 1
   local caps = stack:get_tool_capabilities()
   if caps and caps.max_drop_level and caps.max_drop_level > 1 then
      mdl = caps.max_drop_level
   end
   return looting, mdl
end

-- Apply the looting bonus pass to a drop table. Additive: EXTRA loot on top of
-- the base drops. For each entry, with probability looting/(looting+1) the item
-- gets one bonus roll AT ITS OWN CHANCE (rarity preserved); if that roll lands,
-- a stack of random(min,max) * random(1,max_drop_level) is dropped. No-op when
-- looting <= 0.
local function zombie_looting_bonus(drop_table, pos, looting, max_drop_level)
   if looting <= 0 then return end
   local p_ticket = looting / (looting + 1)   -- L1=.5, L2≈.667, L3=.75
   for _, d in ipairs(drop_table) do
      -- Do we get an extra ticket for this item?
      if math.random(10, 100) / 100 < p_ticket then
         -- The extra ticket still has to pass the item's OWN rarity gate.
         if math.random(d.chance) == 1 then
            local lo = d.min or 1
            local hi = d.max or lo
            if lo < 1 then lo = 1 end
            if hi < lo then hi = lo end
            local base = math.random(lo, hi)
            local mult = max_drop_level > 1 and math.random(1, max_drop_level) or 1
            zombie_spawn_drop(pos, d.name, base * mult)
         end
      end
   end
end

-- Handle the player-kill-only drops ourselves. This runs from on_die, where
-- self.cause_of_death is already populated by mobs_redo. We drop these items
-- ONLY when a player landed the killing blow, and always give at least the
-- listed minimum (never a phantom zero). If the killing weapon has looting,
-- both the valuables here AND the common scraps get a bonus pass.
local function zombie_player_drops(self, pos)
   local cod = self.cause_of_death
   -- Match mobs_redo's own player check: puncher must be present, userdata,
   -- and pass is_player. The userdata guard prevents is_player from erroring
   -- on an unexpected value.
   local p = cod and cod.puncher
   local killer_is_player =
      p and type(p) == 'userdata' and minetest.is_player(p)
   if not killer_is_player then return end   -- no player kill => no special loot

   -- Base valuable drops (guaranteed >= 1 when they roll).
   for _, d in ipairs(player_only_drops) do
      if math.random(d.chance) == 1 then
         local lo = d.min or 1
         local hi = d.max or lo
         if lo < 1 then lo = 1 end           -- hard guarantee: never zero
         if hi < lo then hi = lo end
         zombie_spawn_drop(pos, d.name, math.random(lo, hi))
      end
   end

   -- Looting bonus pass (additive), applied to BOTH tiers. The common scraps'
   -- BASE drops were already handled by mobs_redo; here we add only their
   -- looting bonus, alongside the valuables' bonus. No-op without looting.
   local looting, mdl = zombie_get_looting(p)
   if looting > 0 then
      zombie_looting_bonus(player_only_drops, pos, looting, mdl)
      zombie_looting_bonus(inventory, pos, looting, mdl)
   end
end

-- Option B death sound. mobs_redo calls on_die(self, pos) when the mob dies.
-- We roll a 1-in-DEATH_SOUND_CHANCE gate so the death cry is usually silent
-- and only occasionally heard. Played at pos (not attached to the object,
-- which is about to be removed) so it isn't cut short by the entity's removal.
-- This hook also handles the player-kill-only loot (see zombie_player_drops).
-- Returns nothing (nil) so mobs_redo proceeds with its normal removal.
local function zombie_on_die(self, pos)
   -- Resolve a usable position first; both the drops and the sound need it.
   local at = pos
   if not at and self and self.object then
      local ok, p = pcall(function() return self.object:get_pos() end)
      if ok then at = p end
   end

   -- Player-kill-only loot (guaranteed >= 1, never from environmental deaths).
   if at then
      zombie_player_drops(self, at)
   end

   -- Occasional death cry.
   if math.random(DEATH_SOUND_CHANCE) ~= 1 then return end
   if not at then return end
   minetest.sound_play(DEATH_SOUND, {
      pos = at,
      max_hear_distance = noise.distance,
      pitch = 1.0 + math.random(-10, 10) * 0.005,
   }, true)
end

mobs:register_mob('zombies:1arm', {
   type = 'monster',
   passive = false,
   attack_type = 'dogfight',
   pathfinding = true,
   reach = 2,
   damage = 4,
   damage_max = 4,
   damage_chance = 75,
   hp_min = 3,
   hp_max = 30,
   armor = 80,
   collisionbox = {-0.4, -1, -0.4, 0.4, 0.8, 0.4},
   visual = 'mesh',
   mesh = 'zombie_one-arm.b3d',
   textures = zombies.skins,
   blood_texture = 'default_wood.png',
   makes_footstep_sound = true,
   sounds = noise,
   do_custom = make_sound_throttle(),
   on_die = zombie_on_die,
   walk_velocity = 2,
   run_velocity = 4,
   jump = true,
   view_range = 15,
   drops = inventory,
   lava_damage = 5,
   light_damage = 1,
   fall_damage = 2,
   animation = {
      speed_normal = 10,
      speed_run = 10,
      punch_speed = 20,
      walk_start = 0,
      walk_end = 20,
      run_start = 0,
      run_end = 20,
      punch_start = 21,
      punch_end = 51,
   },
})

mobs:register_mob('zombies:crawler', {
   type = 'monster',
   passive = false,
   attack_type = 'dogfight',
   pathfinding = true,
   reach = 2,
   damage = 4,
   damage_max = 4,
   damage_chance = 75,
   hp_min = 1,
   hp_max = 20,
   armor = 80,
   collisionbox = {-0.5, -.5, -0.4, 0.5, 0.2, 0.4},
   visual = 'mesh',
   mesh = 'zombie_crawler.b3d',
   textures = zombies.skins,
   blood_texture = 'default_wood.png',
   makes_footstep_sound = true,
   sounds = noise,
   do_custom = make_sound_throttle(),
   on_die = zombie_on_die,
   walk_velocity = .5,
   run_velocity = 1,
   jump = true,
   view_range = 15,
   drops = inventory,
   lava_damage = 5,
   light_damage = 1,
   fall_damage = 2,
   animation = {
      speed_normal = 10,
      speed_run = 10,
      punch_speed = 60,
      walk_start = 0,
      walk_end = 40,
      run_start = 0,
      run_end = 40,
      punch_start = 41,
      punch_end = 71,
   },
})

mobs:register_mob('zombies:normal', {
   type = 'monster',
   passive = false,
   attack_type = 'dogfight',
   pathfinding = true,
   reach = 3,
   damage = 4,
   damage_max = 4,
   damage_chance = 75,
   hp_min = 1,
   hp_max = 40,
   armor = 80,
   collisionbox = {-0.4, -1, -0.4, 0.4, 0.8, 0.4},
   visual = 'mesh',
   mesh = 'zombie_normal.b3d',
   textures = zombies.skins,
   blood_texture = 'default_wood.png',
   makes_footstep_sound = true,
   sounds = noise,
   do_custom = make_sound_throttle(),
   on_die = zombie_on_die,
   walk_velocity = 2,
   run_velocity = 4,
   jump = true,
   view_range = 15,
   drops = inventory,
   lava_damage = 5,
   light_damage = 1,
   fall_damage = 2,
   owner_loyal = true, -- tamed zombies attack whatever their owner punches
   animation = {
      speed_normal = 20,
      speed_run = 20,
      punch_speed = 20,
      stand_start = 0,
      stand_end = 40,
      walk_start = 41,
      walk_end = 101,
      run_start = 41,
      run_end = 101,
      punch_start = 102,
      punch_end = 142,
   },
   on_spawn = function(self)
      local phase = moon_phases.get_phase()
      if phase == 4 then
         self.object:set_properties({
            visual_size = {
               x = self.base_size.x * 2,
               y = self.base_size.y * 2
            },
            collisionbox = {
               self.base_colbox[1] * 2,
               self.base_colbox[2] * 2,
               self.base_colbox[3] * 2,
               self.base_colbox[4] * 2,
               self.base_colbox[5] * 2,
               self.base_colbox[6] * 2
            },
         })
      end
   end,
   on_rightclick = function(self, clicker)
      local item = clicker:get_wielded_item()
      local player = clicker:get_player_name()
      -- Owner interaction: right-click toggles Follow / Stay (native
      -- mobs_redo NPC owner-follow; only the owner is ever followed).
      if self.owner == player and self.owner ~= '' then
         if self.order == 'follow' then
            self.order = 'stand'
            minetest.chat_send_player(player, '[Zombie] It stands guard here.')
         else
            self.order = 'follow'
            minetest.chat_send_player(player, '[Zombie] It shambles after you.')
         end
         return
      end
      if item:get_name() == 'zombies:tooth' then
         if self.owner and self.owner ~= '' then
            minetest.chat_send_player(player, '[Zombie] This zombie already has an owner.')
            return
         end
         if item:get_count() >= 3 then
            minetest.chat_send_player(player, '[Zombie] Braaaaaiiiiiiiiiinnnnnnnssssssssssssss')
            self.owner = player
            self.tamed = true
            -- Become an NPC: in mobs_redo, type 'monster' is hard-coded as
            -- untameable -- monsters attack owners (the tamed 'must be
            -- provoked' exemption excludes monsters), cannot owner-follow
            -- (NPC-only), and are flagged static_save=false at activation
            -- while wild (so they vanish on restart). Converting to 'npc'
            -- at taming fixes all three at the source. The type persists
            -- via staticdata.
            self.type = 'npc'
            -- Undo the static_save=false the engine applied while this
            -- entity was a wild monster, or it is discarded on unload.
            self.object:set_properties({static_save = true})
            self.static_save = true
            self.order = 'stand'
            self.light_damage = 0
            -- clear any aggro from before taming (it may have been mid-attack)
            self.attack = nil
            self.following = nil
            self.state = 'stand'
            -- Belt-and-suspenders: do_attack override refuses the owner
            zombie_guard_owner(self)
            item:take_item(3)
            clicker:set_wielded_item(item)
            minetest.chat_send_player(player,
               '[Zombie] It is yours now. Right-click it to make it follow or stay.')
         else
            minetest.chat_send_player(player, '[Zombie] The zombie eyes your tooth hungrily. It wants 3...')
         end
      end
   end,
})


--Spawn Functions
if not mobs.custom_spawn_monster then

   mobs:spawn({
      name = 'zombies:1arm',
      nodes = {'default:dirt_with_grass'},
      min_light = 0,
      max_light = 7,
      chance = 6000,
      active_object_count = 2,
      min_height = 0,
      day_toggle = false
   })

   mobs:spawn({
      name = 'zombies:crawler',
      nodes = {'default:dirt_with_grass'},
      min_light = 0,
      max_light = 7,
      chance = 6000,
      active_object_count = 2,
      min_height = 0,
      day_toggle = false
   })

   mobs:spawn({
      name = 'zombies:normal',
      nodes = {'default:dirt_with_grass'},
      min_light = 0,
      max_light = 7,
      chance = 6000,
      active_object_count = 2,
      min_height = 0,
      day_toggle = false
   })


end

-- Rail corridor zombie spawners
-- Self-contained placement via an LBM that fires as rail-containing
-- mapblocks activate: straight rail runs get a camouflaged spawner embedded
-- in the corridor floor BESIDE the track. No dependence on tsm's
-- webperlin/cobweb spawner system: every corridor of sufficient length is
-- spawner-capable, in any stone type, including in existing worlds.

if minetest.get_modpath('tsm_railcorridors') then

   -- Tuning knobs
   local CORRIDOR_MIN_RUN = 10        -- min contiguous rails in a straight line
   local CORRIDOR_MAX_LIGHT = 13      -- spawn threshold; torches max out at 12,
                                      -- sunlight is 15, so corridors always
                                      -- qualify but surface daylight never does
   local CORRIDOR_TIMER_MIN = 12
   local CORRIDOR_TIMER_MAX = 25

   -- Shared spawn timer for all corridor spawner variants
   local function corridor_spawner_timer(pos)
      local zombie_types = {'zombies:1arm', 'zombies:crawler', 'zombies:normal'}
      local zname = zombie_types[math.random(#zombie_types)]
      local light = minetest.get_node_light(pos) or 0
      if light <= CORRIDOR_MAX_LIGHT then
         -- Axis-aware search: the corridor's direction is stored in node
         -- meta at placement time. Search far along the corridor but only
         -- one node across it, so attempts land on valid corridor floor
         -- and zombies appear down the tunnel rather than failing on walls.
         local axis = minetest.get_meta(pos):get_string('corridor_axis')
         for _ = 1, 16 do
            local offset
            if axis == 'x' then
               offset = {x = math.random(-6, 6), y = 0, z = math.random(-1, 1)}
            elseif axis == 'z' then
               offset = {x = math.random(-1, 1), y = 0, z = math.random(-6, 6)}
            else
               offset = {x = math.random(-6, 6), y = 0, z = math.random(-6, 6)}
            end
            local try = vector.add(pos, offset)
            local above = vector.add(try, {x=0, y=1, z=0})
            local node_there = minetest.get_node(try)
            local node_above = minetest.get_node(above)
            local def = minetest.registered_nodes[node_there.name]
            if def and def.walkable and node_above.name == 'air' then
               local too_close = false
               for _, player in ipairs(minetest.get_connected_players()) do
                  if vector.distance(player:get_pos(), above) < 12 then
                     too_close = true
                     break
                  end
               end
               if not too_close then
                  local nearby = 0
                  for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 20)) do
                     local ent = obj:get_luaentity()
                     if ent and (ent.name == 'zombies:1arm' or
                                 ent.name == 'zombies:crawler' or
                                 ent.name == 'zombies:normal') then
                        nearby = nearby + 1
                     end
                  end
                  if nearby < 8 then
                     minetest.add_entity(above, zname)
                  end
               end
               break
            end
         end
      end
      minetest.get_node_timer(pos):start(math.random(CORRIDOR_TIMER_MIN, CORRIDOR_TIMER_MAX))
      return false
   end

   -- Camouflage spawner variants: one node per common corridor floor type,
   -- copying tiles/sounds/drop from the real node so the spawner is visually
   -- identical to the floor it replaces. Luanti cannot retexture a node
   -- per-instance, hence a small registered family with a lookup table.
   -- 'zombies:corridor_spawner' (stone-look) is kept as the name of the
   -- stone variant and as the fallback for unlisted floor types.
   local floor_to_spawner = {}

   local camo_floors = {
      'default:stone',
      'default:sandstone',
      'default:desert_stone',
      'default:desert_sand',
      'default:silver_sandstone',
      'default:dirt',
      'default:gravel',
      'default:cobble',
   }

   for _, floor_name in ipairs(camo_floors) do
      local srcdef = minetest.registered_nodes[floor_name]
      if srcdef then
         local vname
         if floor_name == 'default:stone' then
            vname = 'zombies:corridor_spawner'
         else
            vname = 'zombies:corridor_spawner_' .. floor_name:gsub('.*:', '')
         end
         minetest.register_node(vname, {
            description = 'Zombie Corridor Spawner (' .. floor_name .. ')',
            tiles = table.copy(srcdef.tiles),
            sounds = srcdef.sounds,
            groups = {cracky = 3, not_in_creative_inventory = 1, zombie_spawner = 1},
            drop = floor_name,
            is_ground_content = false, -- protect from cave carving / overwrites
            on_construct = function(pos)
               minetest.get_node_timer(pos):start(math.random(CORRIDOR_TIMER_MIN, CORRIDOR_TIMER_MAX))
            end,
            on_timer = corridor_spawner_timer,
         })
         floor_to_spawner[floor_name] = vname
      end
   end

   -- Corridor detection: count contiguous rails at the same height along one
   -- axis through a candidate rail position.
   local function rail_run_length(pos, rail_name, axis)
      local count = 1
      for sign = -1, 1, 2 do
         local step = 1
         while step <= CORRIDOR_MIN_RUN do
            local p = {x = pos.x, y = pos.y, z = pos.z}
            p[axis] = p[axis] + sign * step
            if minetest.get_node(p).name ~= rail_name then break end
            count = count + 1
            step = step + 1
         end
      end
      return count
   end

   -- Placement via LBM (Loading Block Modifier): fires once per 16x16x16
   -- mapblock on first activation, regardless of generation order. tsm carves
   -- whole corridor systems from a single chunk's on_generated, spilling rails
   -- into neighbouring chunks -- a generation-time scan misses most of them.
   -- The LBM catches every rail-containing block whenever it first activates,
   -- which also retrofits corridors in existing worlds on first visit.
   local CORRIDOR_SPAWNER_SPACING = 18 -- min distance between spawners
   local CORRIDOR_GATE = 12            -- deterministic 1-in-N gate per rail

   local rail_name = (tsm_railcorridors.nodes and tsm_railcorridors.nodes.rail)
      or 'carts:rail'

   -- run_at_every_load = true: on a block's FIRST activation its neighbours
   -- are often not loaded yet, so the rail-run walk reads 'ignore' and fails.
   -- Re-running on every load self-heals those misses; the spacing check
   -- against group:zombie_spawner makes repeated runs idempotent (once a
   -- spawner exists nearby, later passes are no-ops).
   minetest.register_lbm({
      name = 'zombies:seed_corridor_spawners',
      nodenames = {rail_name},
      run_at_every_load = true,
      action = function(pos, node)
         if pos.y > 0 then return end
         -- Deterministic per-position gate so a block full of rails yields
         -- at most a few candidates, identically on every world load.
         local seed = pos.x * 73856093 + pos.y * 19349663 + pos.z * 83492791
         if PcgRandom(seed):next(1, CORRIDOR_GATE) ~= 1 then return end
         -- Must sit in a straight run of rails (filters stubs / cart sidings)
         local axis
         if rail_run_length(pos, rail_name, 'x') >= CORRIDOR_MIN_RUN then
            axis = 'x'
         elseif rail_run_length(pos, rail_name, 'z') >= CORRIDOR_MIN_RUN then
            axis = 'z'
         end
         if not axis then return end
         -- Spacing: skip if any zombie spawner (corridor or dungeon) is near
         local sp = CORRIDOR_SPAWNER_SPACING
         local near = minetest.find_nodes_in_area(
            {x = pos.x - sp, y = pos.y - sp, z = pos.z - sp},
            {x = pos.x + sp, y = pos.y + sp, z = pos.z + sp},
            'group:zombie_spawner')
         if #near > 0 then return end
         -- Embed a camouflaged spawner in the floor beside the rail
         local perp = (axis == 'x') and 'z' or 'x'
         local first = PcgRandom(seed + 1):next(0, 1) == 0 and 1 or -1
         for _, side in ipairs({first, -first}) do
            local floor_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
            floor_pos[perp] = floor_pos[perp] + side
            local above_pos = {x = floor_pos.x, y = floor_pos.y + 1, z = floor_pos.z}
            local floor_node = minetest.get_node(floor_pos)
            local floor_def = minetest.registered_nodes[floor_node.name]
            if floor_def and floor_def.walkable
                  and minetest.get_node(above_pos).name == 'air'
                  and not floor_node.name:find('^zombies:') then
               local spawner = floor_to_spawner[floor_node.name]
                  or 'zombies:corridor_spawner'
               minetest.set_node(floor_pos, {name = spawner})
               minetest.get_meta(floor_pos):set_string('corridor_axis', axis)
               minetest.log('action', '[zombies] corridor spawner ('
                  .. spawner .. ') placed at '
                  .. minetest.pos_to_string(floor_pos))
               return
            end
         end
      end,
   })
end

-- Dungeonsplus dungeon room zombie spawner
-- Uses dungeonsplus.register_dungeon_feature() to place a hidden spawner node
-- on the floor of dungeon rooms (~1 zombie per 21 seconds per room, mixed
-- types, cap of 8 nearby). Spawner nodes are the sole dungeon spawn system;
-- the earlier mossycobble ABM was removed in favour of them.
-- The spawner node is invisible, looks like mossycobble, drops mossycobble,
-- and is not in the creative inventory.

-- Dungeon spawner nodes and timer are registered unconditionally: they are
-- used by the dungeonsplus feature (new rooms), the retrofit LBM (existing
-- vanilla/old dungeons), and manual placement. Only the dungeonsplus feature
-- registration itself is guarded below.

-- Shared on_timer logic for dungeon spawner (same shape as corridor spawner)
local function dungeon_spawner_timer(pos)
   local zombie_types = {'zombies:1arm', 'zombies:crawler', 'zombies:normal'}
   local zname = zombie_types[math.random(#zombie_types)]
   local light = minetest.get_node_light(pos) or 0
   if light <= 10 then
      for _ = 1, 10 do
         local offset = {
            x = math.random(-6, 6),
            y = 0,
            z = math.random(-6, 6)
         }
         local try = vector.add(pos, offset)
         local above = vector.add(try, {x=0, y=1, z=0})
         local node_there = minetest.get_node(try)
         local node_above = minetest.get_node(above)
         local def = minetest.registered_nodes[node_there.name]
         if def and def.walkable and node_above.name == 'air' then
            local too_close = false
            for _, player in ipairs(minetest.get_connected_players()) do
               if vector.distance(player:get_pos(), above) < 12 then
                  too_close = true
                  break
               end
            end
            if not too_close then
               local nearby = 0
               for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 20)) do
                  local ent = obj:get_luaentity()
                  if ent and (ent.name == 'zombies:1arm' or
                              ent.name == 'zombies:crawler' or
                              ent.name == 'zombies:normal') then
                     nearby = nearby + 1
                  end
               end
               if nearby < 8 then
                  minetest.add_entity(above, zname)
               end
            end
            break
         end
      end
   end
   -- Retrigger: random 18-25s matches ~1 zombie per 21s average (ABM parity)
   minetest.get_node_timer(pos):start(math.random(18, 25))
   return false
end

-- Camouflage spawner variants: one per mapgen dungeon floor material,
-- copying tiles/sounds/drop from the real node so the spawner blends into
-- the dungeon it's placed in. 'zombies:dungeon_spawner' keeps its original
-- name (mossycobble-look) so spawners in existing worlds stay valid.
-- Unknown floor materials fall back to the cobble-look variant, which
-- suits dungeons generically.
local dungeon_floor_to_spawner = {}

local dungeon_camo_floors = {
   'default:mossycobble',
   'default:cobble',
   'default:sandstonebrick',
   'default:desert_stone',
   'default:ice',
}

for _, floor_name in ipairs(dungeon_camo_floors) do
   local srcdef = minetest.registered_nodes[floor_name]
   if srcdef then
      local vname
      if floor_name == 'default:mossycobble' then
         vname = 'zombies:dungeon_spawner' -- keep original name for compat
      else
         vname = 'zombies:dungeon_spawner_' .. floor_name:gsub('.*:', '')
      end
      minetest.register_node(vname, {
         description = 'Zombie Dungeon Spawner (' .. floor_name .. ')',
         tiles = table.copy(srcdef.tiles),
         sounds = srcdef.sounds,
         groups = {cracky = 3, not_in_creative_inventory = 1, zombie_spawner = 1},
         drop = floor_name,
         is_ground_content = false,
         on_construct = function(pos)
            minetest.get_node_timer(pos):start(math.random(18, 25))
         end,
         on_timer = dungeon_spawner_timer,
      })
      dungeon_floor_to_spawner[floor_name] = vname
   end
end

-- Dungeon retrofit LBM: seeds spawners into already-generated dungeons.
-- default:mossycobble is the engine's dungeon accent node in ~38 biomes and
-- the only safe dungeon signature in existing terrain (sandstonebrick,
-- desert stone and ice are common outside dungeons, so pre-existing
-- dungeons of those types cannot be safely retrofitted; newly generated
-- ones are covered by the dungeonsplus feature instead). When a mossycobble
-- FLOOR node (walkable, air above) passes a deterministic gate, it is
-- replaced in place with the mossycobble-look spawner -- perfect camouflage.
local DUNGEON_SPAWNER_SPACING = 20 -- min distance between spawners
local DUNGEON_GATE = 8             -- deterministic 1-in-N gate per node

minetest.register_lbm({
   name = 'zombies:seed_dungeon_spawners',
   nodenames = {'default:mossycobble'},
   -- every load: retries edge cases where the block above was unloaded on
   -- first activation; spacing check keeps it idempotent
   run_at_every_load = true,
   action = function(pos, node)
      if pos.y > 0 then return end
      local seed = pos.x * 73856093 + pos.y * 19349663 + pos.z * 83492791
      if PcgRandom(seed):next(1, DUNGEON_GATE) ~= 1 then return end
      -- The node itself must be a floor: air directly above it
      local above = {x = pos.x, y = pos.y + 1, z = pos.z}
      if minetest.get_node(above).name ~= 'air' then return end
      -- Spacing against any existing zombie spawner (dungeon or corridor)
      local sp = DUNGEON_SPAWNER_SPACING
      local near = minetest.find_nodes_in_area(
         {x = pos.x - sp, y = pos.y - sp, z = pos.z - sp},
         {x = pos.x + sp, y = pos.y + sp, z = pos.z + sp},
         'group:zombie_spawner')
      if #near > 0 then return end
      minetest.set_node(pos, {name = 'zombies:dungeon_spawner'})
      minetest.log('action', '[zombies] dungeon spawner (retrofit) placed at '
         .. minetest.pos_to_string(pos))
   end,
})

if minetest.get_modpath('dungeonsplus') then

   -- Register as a dungeonsplus floor feature.
   -- Weight 3 places it between forge (4) and bare_floor (2):
   -- appears in roughly 1 in 4 dungeon rooms.
   -- Conditions: room must be enclosed on Y axis (has a ceiling), underground only.
   minetest.register_on_mods_loaded(function()
      if dungeonsplus and dungeonsplus.register_dungeon_feature then
         local reg_ok = dungeonsplus.register_dungeon_feature({
            name = 'Zombie Spawner',
            surfaces = 'floor',
            weight = 3,
            conditions = {
               room = {
                  -- Room must have a ceiling (enclosed vertically)
                  function(room) return room.enclosed and room.enclosed.y end,
                  -- Underground only
                  function(room) return room.pos.y < 0 end,
               },
            },
            generate = function(data)
               local room = data.room
               local va = data.va
               local vdata = data.vdata
               local ystride = data.va.ystride

               -- Place spawner at room center floor position
               local floor_pos = {
                  x = room.pos.x,
                  y = room.min.y,
                  z = room.pos.z
               }

               -- Find the floor: step down from room.pos until we hit a solid node
               local try_pos = {x = floor_pos.x, y = floor_pos.y, z = floor_pos.z}
               for _ = 1, 4 do
                  local idx = va:indexp(try_pos)
                  if idx and vdata[idx] and vdata[idx] ~= minetest.CONTENT_AIR then
                     floor_pos = try_pos
                     break
                  end
                  try_pos.y = try_pos.y - 1
               end

               -- Write spawner node into vdata, camouflaged as the floor
               -- node it replaces (Option A fallback: cobble-look for any
               -- floor material outside the known dungeon set).
               local idx = va:indexp(floor_pos)
               if not idx then return false end
               -- Only place on a solid floor node
               if vdata[idx] == minetest.CONTENT_AIR then return false end
               -- Place one node above the floor (so it's on the floor surface)
               local above_idx = idx + ystride
               if vdata[above_idx] ~= minetest.CONTENT_AIR then return false end
               local floor_name = minetest.get_name_from_content_id(vdata[idx])
               local spawner = dungeon_floor_to_spawner[floor_name]
                  or dungeon_floor_to_spawner['default:cobble']
                  or 'zombies:dungeon_spawner'
               vdata[idx] = minetest.get_content_id(spawner)

               -- Start timer after VoxelManip writes to map
               minetest.after(0, function()
                  minetest.get_node_timer(floor_pos):start(math.random(18, 25))
               end)

               return true
            end,
         })
         minetest.log("action", "[zombies] dungeonsplus Zombie Spawner feature "
            .. (reg_ok and "registered" or "FAILED to register"))
      end
   end)

end

-- Tamed zombies defend their owner: when a player is attacked, their owned
-- zombies within 16 nodes turn on the attacker. They never attack the owner.
minetest.register_on_punchplayer(function(player, hitter)
   if not hitter or hitter == player then return end
   local pname = player:get_player_name()
   for _, obj in ipairs(minetest.get_objects_inside_radius(player:get_pos(), 16)) do
      local ent = obj:get_luaentity()
      if ent and ent.owner == pname and ent.do_attack
            and (ent.name == 'zombies:normal' or ent.name == 'zombies:1arm'
                 or ent.name == 'zombies:crawler') then
         ent:do_attack(hitter)
      end
   end
end)

-- Insurance: rearm any zombie spawner whose timer is not running. Covers
-- crash windows between placement and deferred timer start, and placement
-- paths that bypass on_construct (WorldEdit, schematics). Idempotent and
-- nearly free: only spawner nodes match, and started timers are skipped.
minetest.register_lbm({
   name = 'zombies:rearm_spawners',
   nodenames = {'group:zombie_spawner'},
   run_at_every_load = true,
   action = function(pos, node)
      local timer = minetest.get_node_timer(pos)
      if not timer:is_started() then
         timer:start(math.random(15, 30))
      end
   end,
})

minetest.log("action", "[zombies] mod loaded: surface ABM + dungeon/corridor spawner nodes active"
   .. (minetest.get_modpath("tsm_railcorridors") and ", rail corridor spawner active" or "")
   .. (minetest.get_modpath("dungeonsplus") and ", dungeonsplus spawner feature active" or ""))
