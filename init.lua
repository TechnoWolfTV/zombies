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

local inventory = {
   {name = 'default:dirt', chance = 2, min = 3, max = 5},
   {name = 'default:apple', chance = 6, min = 2, max = 5},
   {name = 'default:clay_lump', chance = 10, min = 1, max = 4},
   {name = 'bonemeal:bone', chance = 3, min = 0, max = 10},
   {name = 'zombies:tooth', chance = 10, min = 0, max = 3},
   {name = 'farming:bread', chance = 7, min = 0, max = 2},
   {name = 'default:mese_crystal_fragment', chance = 100, min = 1, max = 2},
   {name = 'mobs:leather', chance = 4, min = 1, max = 3},
   {name = 'tnt:gunpowder', chance = 100, min = 0, max = 1},
   {name = 'default:coal_lump', chance = 5, min = 0, max = 1},
   {name = 'default:sword_mese', chance = 1000, min = 0, max = 1},
   {name = 'default:diamond', chance = 300, min = 1, max = 1},
   {name = 'default:sword_diamond', chance = 1500, min = 1, max = 1},
   {name = 'default:diamondblock', chance = 5000, min = 1, max = 1}
}

-- Currency drops are optional: only added if the currency mod is installed
if minetest.get_modpath('currency') then
   local currency_drops = {
      {name = 'currency:minegeld_cent_5',  chance = 3,    min = 1, max = 5},
      {name = 'currency:minegeld_cent_10', chance = 5,    min = 1, max = 3},
      {name = 'currency:minegeld_cent_25', chance = 8,    min = 1, max = 2},
      {name = 'currency:minegeld',         chance = 20,   min = 1, max = 3},
      {name = 'currency:minegeld_5',       chance = 75,   min = 1, max = 2},
      {name = 'currency:minegeld_10',      chance = 200,  min = 1, max = 1},
      {name = 'currency:minegeld_50',      chance = 500,  min = 1, max = 1},
      {name = 'currency:minegeld_100',     chance = 2000, min = 1, max = 1},
   }
   for _, drop in ipairs(currency_drops) do
      table.insert(inventory, drop)
   end
end

local noise = {
   distance = 10,
   random = 'groan',
   war_cry = 'groan',
   damage = 'groan',
   death = 'eating-brains',
}

-- Ambient moan fires every MOAN_MIN to MOAN_MAX seconds per zombie (random)
local MOAN_MIN = 4
local MOAN_MAX = 12
-- War cry / damage sounds are throttled to at most once per COMBAT_COOLDOWN seconds
local COMBAT_COOLDOWN = 2.5

-- Installs a per-entity do_attack override that refuses the owner as a
-- target. do_attack is the single function all attack acquisition in
-- mobs_redo funnels through, so this is a hard guarantee the zombie can
-- never attack its owner, regardless of state, save data, or timing.
local function zombie_guard_owner(self)
   if self._owner_guarded then return end
   local original_do_attack = self.do_attack
   self.do_attack = function(s, target, force)
      if target and target.get_player_name then
         local ok, tname = pcall(function() return target:get_player_name() end)
         if ok and tname == s.owner and s.owner ~= '' then
            return
         end
      end
      return original_do_attack(s, target, force)
   end
   self._owner_guarded = true
end

local function make_sound_throttle()
   return function(self, dtime)
      if not self._sound_patched then
         -- per-entity timers
         self._combat_timer = 0
         self._moan_timer = math.random(MOAN_MIN, MOAN_MAX)

         local original_mob_sound = self.mob_sound
         self.mob_sound = function(s, sound)
            if not sound then return end
            local name = type(sound) == 'string' and sound or sound.name
            -- death always plays unthrottled
            if name == noise.death then
               return original_mob_sound(s, sound)
            end
            -- combat sounds (war_cry, damage) throttled by COMBAT_COOLDOWN
            if s._combat_timer and s._combat_timer <= 0 then
               original_mob_sound(s, sound)
               s._combat_timer = COMBAT_COOLDOWN
            end
         end
         self._sound_patched = true
      end

      -- tick combat cooldown
      if self._combat_timer and self._combat_timer > 0 then
         self._combat_timer = self._combat_timer - dtime
      end

      -- Tamed-zombie loyalty upkeep (runs every step for owned zombies):
      -- only follow the owner (strangers holding teeth cannot lure it away),
      -- and NEVER hold the owner as an attack target under any circumstance.
      if self.owner and self.owner ~= '' then
         -- Ensure the do_attack owner-guard is installed (covers zombies
         -- tamed under older versions or loaded fresh from staticdata).
         if not self._owner_guarded then
            zombie_guard_owner(self)
         end
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
            minetest.sound_play('groan', {
               object = self.object,
               max_hear_distance = noise.distance,
               pitch = 1.0 + math.random(-10, 10) * 0.005,
            }, true)
            self._moan_timer = math.random(MOAN_MIN, MOAN_MAX)
         end
      end
   end
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
