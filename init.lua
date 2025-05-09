dofile(core.get_modpath("placement_preview") .. "/utils.lua")
local mod_name = "placement_preview"

--to disable some un-needed stuff
local dev_mode = false

-- how much the PP glows
local glow_amount = 4
local g_smooth = false           --(not great on servers)smooth preview movement, otherwise snaps. players default to the this setting but can individually set it.
local g_pulse = false
local g_only_stairs_slabs = true --only wanna preview nodes with special placement

---@type number
local reach_distance = 3.0 --this should actaully just be the player's reach distance

---@type table
Player_data = {}

local function ghost_objectAnimation()
	for _, p in ipairs(Player_data) do
		if p.ghost_object ~= nil then
			if g_pulse == false then
				local size = { x = 0.1, y = 0.1, z = 0.1 }
				return
			end
			if p.grow == true then
				local size = { x = 0.1, y = 0.1, z = 0.1 }
				p.ghost_object:set_properties({ visual_size = size })
				p.grow = false
			end
			local size = p.ghost_object:get_properties().visual_size
			local amount = 0
			if p.ghost_object_grow == true then
				if size.x < 0.5 then
					amount = 0.08
				elseif size.x <= 0.6 then
					amount = 0.008
				else
					p.ghost_object_grow = false
				end
			end
			if p.ghost_object_grow == false then
				if size.x >= 0.58 then
					amount = -0.008
				else
					p.ghost_object_grow = true
				end
			end
			local new_size = { x = size.x + amount, y = size.y + amount, z = size.z + amount }
			p.ghost_object:set_properties({ visual_size = new_size })
		end
	end
end

function Player_data.addPlayer(name)
	local p_data = {
		player_name = name,
		ghost_object = nil,
		ghost_object_grow = true,
		rotation = { x = 0, y = 0, z = 0 },
		disabled = false,
		node_paramtype2 = nil,
		connected = false,
		double_slab = nil,
		smooth = g_smooth,
		only_stairs_slabs = g_only_stairs_slabs,
		grow = false,
		removePreview = function(self)
			if self.ghost_object ~= nil then
				self.ghost_object:remove()
				self.ghost_object = nil
			end
		end,
	}
	table.insert(Player_data, p_data)
	return p_data
end

---@alias data table

---@return data
function Player_data.getPlayer(name)
	for _, p in ipairs(Player_data) do
		if p.player_name == name then
			return p
		end
	end
	return Player_data.addPlayer(name)
end

local cmd = {
	params = "help",
	-- params = "[on|off] or [enable|disable] or [true|false]",
	description = "disable or enable the placement preview",
	privs = {},
	func = function(name, param)
		local player = Player_data.getPlayer(name)
		local fields = Utils.Split(param, " ")
		local error_msg = function()
			minetest.chat_send_player(name,
				minetest.colorize("red", "You may be brain dead.. example: \n\t /placement_preview help \n\t or \n\t /pp help"))
		end
		if #fields == 1 then
			if param == "on" or param == "true" or param == "enable" then
				player.disabled = false
				minetest.chat_send_player(name, minetest.colorize("cyan", "placement_preview has been enable"))
			elseif param == "off" or param == "false" or param == "disable" then
				player.disabled = true
				minetest.chat_send_player(name, minetest.colorize("cyan", "placement_preview has been disabled"))
			elseif param == "help" then
				minetest.chat_send_player(name,
					minetest.colorize("cyan",
						table.concat({
							"list of commands: \n",
							"\t [true|false] \n",
							"\t smooth [true|false] \n",
							"\t pulse_animation [true|false] \n",
							"\t only_stairs_slabs [true|false] \n",
						})
					))
			else
				error_msg()
			end
		end
		if #fields > 1 then
			local option = fields[1]
			local value = fields[2]
			if option == "smooth" then
				if value == "true" then
					player.smooth = true
				elseif value == "false" then
					player.smooth = false
				else
					error_msg()
					return
				end
				minetest.chat_send_player(name, minetest.colorize("cyan", string.format("pp smooth is now: " .. value)))
				return
			end
			if option == "only_stairs_slabs" then
				if value == "true" then
					player.only_stairs_slabs = true
				elseif value == "false" then
					player.only_stairs_slabs = false
				else
					error_msg()
					return
				end
				minetest.chat_send_player(name,
					minetest.colorize("cyan", string.format("pp only_stairs_slabs is now: " .. value)))
				return
			end
			if option == "pulse_animation" then
				if value == "true" then
					g_pulse = true
				elseif value == "false" then
					g_pulse = false
				else
					error_msg()
					return
				end
				minetest.chat_send_player(name,
					minetest.colorize("cyan", string.format("pp pulse_animation is now: " .. value)))
				return
			end
			error_msg()
		end
	end,
}

minetest.register_chatcommand("placement_preview", cmd)
minetest.register_chatcommand("pp", cmd)


---gets the placement to match the preview
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	--Guard against nil placer
	if not placer then
		return
	end

	local p_data = Player_data.getPlayer(placer:get_player_name())
	-- core.log("face.."..core.dir_to_facedir(placer:get_look_dir()))
	p_data.grow = true
	-- newnode.param2 = minetest.dir_to_facedir(p_data.rotation, true)
	-- minetest.swap_node(pos, newnode)
	-- goto all_done

	--check if only stairs option
	if p_data.only_stairs_slabs == true then
		if Utils.StringContains(newnode.name, "stair") ~= nil or Utils.StringContains(newnode.name, "slab") ~= nil then
		else
			return
		end
	end
	--check if wallmounted or nil
	if p_data.node_paramtype2 == nil or p_data.node_paramtype2 == "wallmounted" or p_data.node_paramtype2 == "none" then
		return
	end
	--Doors kinda get placed werid otherwise
	if Utils.StringContains(newnode.name, "door") ~= nil then
		return
	end

	if p_data.node_paramtype2 == "facedir" then
		-- if Utils.StringContains(newnode.name, "STAIR") ~= nil or Utils.StringContains(newnode.name, "STAIRS") ~= nil then
		-- core.log("working with y:"..math.deg(p_data.rotation.y).." x:"..math.deg(p_data.rotation.x))
		local face = 0
		local amount = 90
		local vert_slab = false

		if Utils.StringContains(newnode.name, "stair") ~= nil then
			--FIXME(not sure this is true anymore): placing on top/vertically does not work
			--(ONLY)support for inner and outer stairs
			if Utils.StringContains(newnode.name, "outer") ~= nil or Utils.StringContains(newnode.name, "inner") ~= nil
					or
					p_data.connected == true
			then
				if p_data.connected == true then
					-- core.log("we are connecting connected?")
					local is_connected = core.registered_nodes[p_data.ghost_object:get_properties().wield_item]
					if Utils.StringContains(is_connected.name, "outer") ~= nil or Utils.StringContains(is_connected.name, "inner") ~= nil then
						-- core.log("what the fuck does this say? " .. newnode.name)
						local new_node = {
							name = is_connected.name,
							param2 = 0,
						}
						newnode = new_node
						-- core.log("switch to: " .. newnode.name)
					end
				end
				-- 	core.log("this should be switched to be an outer/inner node")
				-- local rot = p_data.rotation
				-- core.log("the rotation is" .. dump(p_data.rotation))
				-- minetest.debug(string.format("rotation: %s,%s,%s", math.deg(rot.x), math.deg(rot.y), math.deg(rot.z)))
				-- face = core.dir_to_facedir(placer:get_look_dir(),true)
				-- goto done
				if math.deg(p_data.rotation.y) == 360 then
					if math.deg(p_data.rotation.x) == 0 then
						face = 0
					else
						face = 22
					end
				end
				if math.deg(p_data.rotation.y) == 270 then
					if math.deg(p_data.rotation.x) == 0 then
						face = 1
					else
						face = 21
					end
				end
				if math.deg(p_data.rotation.y) == 540 then
					if math.deg(p_data.rotation.x) == 0 then
						face = 2
					else
						face = 20
					end
				end
				if math.deg(p_data.rotation.y) == 450 then
					if math.deg(p_data.rotation.x) == 0 then
						face = 3
					else
						face = 23
					end
				end
				if math.deg(p_data.rotation.y) == 90 then
					if math.deg(p_data.rotation.x) == 0 then
						face = 3
					elseif math.deg(p_data.rotation.x) == 180 then
						face = 23
					else
						face = 20
					end
				end
				if math.deg(p_data.rotation.y) == 180 then
					if math.deg(p_data.rotation.x) == 0 then
						face = 2
					else
						face = 20
					end
				end
				if math.deg(p_data.rotation.y) == 0 then
					if math.deg(p_data.rotation.x) == 180 then
						face = 22
					end
				end
				-- core.log("face has been set to: " .. face)
				goto done
			end
		end



		if math.deg(p_data.rotation.y) == 0 then
			face = 0
		end
		if math.deg(p_data.rotation.y) == 270 then
			face = 1
		end
		if math.deg(p_data.rotation.y) == 180 then
			face = 2
		end
		if math.deg(p_data.rotation.y) == 90 then
			face = 3
		end


		if placer:get_player_control()["sneak"] == true then
			--if sneaking leave at previous amount.. we are making walls
			if Utils.StringContains(newnode.name, "SLAB") ~= nil then
				vert_slab = true
			else
				-- if Utils.StringContains(newnode.name, "STAIR") ~= nil or Utils.StringContains(newnode.name, "STAIRS") ~= nil then
				if math.deg(p_data.rotation.y) == 270 and math.deg(p_data.rotation.z) == 270 then
					face = 5
					goto done
				end
				if math.deg(p_data.rotation.y) == 270 and math.deg(p_data.rotation.z) == 90 then
					face = 9
					goto done
				end
				if math.deg(p_data.rotation.y) == 90 and math.deg(p_data.rotation.z) == 90 then
					face = 7
					goto done
				end
				if math.deg(p_data.rotation.y) == 90 and math.deg(p_data.rotation.z) == 270 then
					face = 12
					goto done
				end
				if math.deg(p_data.rotation.y) == 0 and math.deg(p_data.rotation.z) == 90 then
					face = 12
					goto done
				end
				if math.deg(p_data.rotation.y) == 0 and math.deg(p_data.rotation.z) == 270 then
					face = 9
					goto done
				end
				if math.deg(p_data.rotation.y) == 180 and math.deg(p_data.rotation.z) == 90 then
					face = 18
					goto done
				end
				if math.deg(p_data.rotation.y) == 180 and math.deg(p_data.rotation.z) == 270 then
					face = 7
					goto done
				end
			end
		end

		if vert_slab == false then
			if Utils.StringContains(newnode.name, "SLAB") ~= nil then
				amount = 180
			end
		end

		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 0 then
			if vert_slab == true then
				face = 8
			elseif Utils.StringContains(newnode.name, "SLAB") ~= nil then
				face = 20
			else
				face = 8
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 90 then
			if vert_slab == true then
				face = 15
			elseif Utils.StringContains(newnode.name, "SLAB") ~= nil then
				face = 21
			else
				face = 15
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 180 then
			if vert_slab == true then
				face = 6
			elseif Utils.StringContains(newnode.name, "SLAB") ~= nil then
				face = 22
			else
				face = 6
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 270 then
			if vert_slab == true then
				face = 17
			elseif Utils.StringContains(newnode.name, "SLAB") ~= nil then
				face = 23
			else
				face = 17
			end
		end
		if math.deg(p_data.rotation.x) == -90 then
			face = 4
			goto done
		end

		::done::
		newnode.param2 = face
		core.set_node(pos, newnode)
	else
		return
	end
	::all_done::
end)

local function quantize_direction(yaw)
	local angle = math.deg(yaw) % 360 -- Convert yaw to degrees and get its modulo 360
	if angle < 45 or angle >= 315 then
		return math.rad(0)             -- Facing North
	elseif angle >= 45 and angle < 135 then
		return math.rad(90)            -- Facing East
	elseif angle >= 135 and angle < 225 then
		return math.rad(180)           -- Facing South
	else
		return math.rad(270)           -- Facing West
	end
end


minetest.register_entity(mod_name .. ":" .. "ghost_object", {
	initial_properties = {
		visual = "item",
	},
	wield_item = "default:cobble",
	visual_size = { x = 0.6, y = 0.6, z = 0.6 },
	collisionbox = { -0.2, -0.2, -0.2, 0.2, 0.2, 0.2 }, -- default
	glow = glow_amount,
	static_save = false,
	physical = false,
	pointable = false,
	shaded = true,
	backface_culling = false,
	use_texture_alpha = true,
})

--should only be enabled while doing dev work
if dev_mode then
	minetest.register_node(mod_name .. ":" .. "dev_node_stairs", {
		description = "dev stairs[get orientation]",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
				{ -0.5, -0.0, -0.0, 0.5, 0.5, 0.5 },
			}

		},
		-- tiles = { "default_cobble.png" },
		paramtype2 = "facedir",
		place_param2 = 0,
		groups = { crumbly = 3, oddly_breakable_by_hand = 3 },

		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			node.param2 = node.param2 + 1
			if node.param2 >= 24 then
				node.param2 = 0
			end
			minetest.swap_node(pos, node)
			minetest.debug(minetest.colorize("cyan", string.format("[%s: %s]", node.name, node.param2)))
		end,
	})

	minetest.register_node(mod_name .. ":" .. "dev_node_stairs_inner", {
		description = "dev stairs inner [get orientation]",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
				{ -0.5, -0.0, -0.0, 0.0, 0.5, 0.5 },
			}

		},
		-- tiles = { "default_cobble.png" },
		paramtype2 = "facedir",
		place_param2 = 0,
		groups = { crumbly = 3, oddly_breakable_by_hand = 3 },

		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			node.param2 = node.param2 + 1
			if node.param2 >= 24 then
				node.param2 = 0
			end
			minetest.swap_node(pos, node)
			-- minetest.debug(minetest.colorize("cyan", string.format("[%s: %s]", node.name, node.param2)))
		end,
	})

	minetest.register_node(mod_name .. ":" .. "dev_node_slab", {
		description = "dev slab[get orientation]",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{ -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
			}

		},
		-- tiles = { "default_cobble.png" },
		paramtype2 = "facedir",
		place_param2 = 0,
		groups = { crumbly = 3, oddly_breakable_by_hand = 3 },

		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			node.param2 = node.param2 + 1
			if node.param2 >= 24 then
				node.param2 = 0
			end
			minetest.swap_node(pos, node)
			-- minetest.debug(minetest.colorize("cyan", string.format("[%s: %s]", node.name, node.param2)))
		end,
	})
end

---@class vector table
---@param ghost_pos vector
---@return string|nil,number|nil
-- get the current pos..
-- if there are stairs around it that it could connect to
-- connect
-- just need to check horizontally?
local function shouldConnect(ghost_pos, this_node, pointed_thing)
	local is_connected = false
	local is_outer = false
	local conneted_at = nil
	if Utils.StringContains(this_node.name, "inner") ~= nil or Utils.StringContains(this_node.name, "outer") ~= nil then
		return nil
	end
	if Utils.StringContains(pointed_thing.name, "stair") ~= nil then
		if Utils.StringContains(pointed_thing.name, "slab") == nil then
			is_outer = true
		end
	end
	local to_check = {
		{ { x = -1, y = 0, z = 0 }, { x = 0, y = 0, z = 1 } },
		{ { x = -1, y = 0, z = 0 }, { x = 0, y = 0, z = -1 } },
		{ { x = 1, y = 0, z = 0 },  { x = 0, y = 0, z = -1 } },
		{ { x = 1, y = 0, z = 0 },  { x = 0, y = 0, z = 1 } },
	}
	for index, check in ipairs(to_check) do
		local first = core.get_node(ghost_pos:add(check[1]))
		local second = core.get_node(ghost_pos:add(check[2]))
		if Utils.StringContains(first.name, "stair") ~= nil then
			if Utils.StringContains(second.name, "stair") ~= nil then
				if Utils.StringContains(first.name, "slab") == nil then
					if Utils.StringContains(second.name, "slab") == nil then
						is_connected = true

						--FIXME: kinda works.. i should have it only connect when looking at
						-- the node.. and update a node that could be a coner
						if is_outer == true then
							conneted_at = (90 * (index - 1)) % 360
						else
							conneted_at = (90 * (4 - (index - 1))) % 360
						end
					end
				end
			end
		end
	end
	if is_connected == true then
		if is_outer == true then
			return "outer", conneted_at
		else
			return "inner", conneted_at
		end
	end
	return nil, nil
end


---@class vector table
---@param ghost_pos vector
---@return string|nil,number|nil,boolean|nil
-- get the current pos..
-- if there are stairs around it that it could connect to
-- connect
-- just need to check horizontally?
local function connectTo(p, ghost_pos, this_node, pointed_thing, under, face_pos)
	-- core.log("face_pos " .. dump(face_pos))
	local is_connected = false
	local pointed_at_stairs = false
	local conneted_at = nil
	local p_rot = quantize_direction(p:get_look_horizontal())
	if Utils.StringContains(this_node.name, "inner") ~= nil or Utils.StringContains(this_node.name, "outer") ~= nil then
		return nil, nil
	end
	--prevent preview if potined_thing is a corner varient
	if Utils.StringContains(pointed_thing.name, "inner") or Utils.StringContains(pointed_thing.name, "outer") then
		return nil,nil
	end
	if Utils.StringContains(pointed_thing.name, "stair") ~= nil then
		if Utils.StringContains(pointed_thing.name, "slab") == nil then
			pointed_at_stairs = true
			-- core.log("yes we are looking a stair")
			local face = pointed_thing.param2
			-- core.log("face: " .. pointed_thing.param2)
			local rotaion = math.deg(p_rot)
			-- core.log("face: " .. face)
			-- core.log("p_rot: " .. rotaion)
			-- core.log("face_pos: " .. dump(face_pos))

			--should only really care about sides and not the top or bottom
			--NOTE: This is a lot better
			if face_pos.y == 1 or face_pos.y == -1 then
				-- core.log("Yea lets not fuck with this")
				return nil, nil
			end
			if face == 0 then
				if face_pos.x == 1 then
					return "outer", 0
				end
				if face_pos.x == -1 then
					return "outer", 270
				end
				-- if face_pos.x == 0 then
				-- 	return "outer", 270
				-- end
			end
			if face == 1 then
				if face_pos.z == 1 then
					return "outer", 180
				end
				if face_pos.z == -1 then
					return "outer", 270
				end
			end
			if face == 2 then
				if face_pos.x == 1 then
					return "outer", 90
				end
				if face_pos.x == -1 then
					return "outer", 180
				end
			end
			if face == 3 then
				if face_pos.z == 1 then
					return "outer", 90
				end
				if face_pos.z == -1 then
					return "outer", 0
				end
			end
			--TODO:
			--when placing a stair, look over to its side and if the bottom stair
			--is facing towards the ghost node update those nodes to look like they
			--want to connect
			--need to also check if those nodes have a stair node on both side or not
			--if not then we can go ahead and update them
			--would need to keep a var of that node

			--upside down
			if face == 17 then
				if face_pos.z == 1 then
					return "outer", 90, false
				end
				if face_pos.z == -1 then
					return "outer", 180, false
				end
			end
			if face == 6 then --FIXME: this is not being placed correctly
				if face_pos.x == 1 then
					return "outer", 0, false
				end
				if face_pos.x == -1 then
					-- return "outer", 270, false
					return "outer", 90, false
				end
			end
			if face == 8 then
				if face_pos.x == 1 then
					return "outer", 270, false
				end
				if face_pos.x == -1 then
					return "outer", 180, false
				end
			end
			if face == 15 then
				if face_pos.z == 1 then
					return "outer", 0, false
				end
				if face_pos.z == -1 then
					return "outer", 270, false
				end
			end
		end
	end
	-- local to_check = {
	-- 	{ { x = -1, y = 0, z = 0 }, { x = 0, y = 0, z = 1 } },
	-- 	{ { x = -1, y = 0, z = 0 }, { x = 0, y = 0, z = -1 } },
	-- 	{ { x = 1, y = 0, z = 0 },  { x = 0, y = 0, z = -1 } },
	-- 	{ { x = 1, y = 0, z = 0 },  { x = 0, y = 0, z = 1 } },
	-- }
	-- for index, check in ipairs(to_check) do
	-- 	local first = core.get_node(ghost_pos:add(check[1]))
	-- 	local second = core.get_node(ghost_pos:add(check[2]))
	-- 	if Utils.StringContains(first.name, "stair") ~= nil then
	-- 		if Utils.StringContains(second.name, "stair") ~= nil then
	-- 			if Utils.StringContains(first.name, "slab") == nil then
	-- 				if Utils.StringContains(second.name, "slab") == nil then
	-- 					is_connected = true

	-- 					--FIXME: kinda works.. i should have it only connect when looking at
	-- 					-- the node.. and update a node that could be a coner
	-- 					if pointed_at_stairs == true then
	-- 						conneted_at = (90 * (index - 1)) % 360
	-- 					else
	-- 						core.log("looks odd")
	-- 						local rot = (90 * (4 - (index - 1))) % 360
	-- 						if rot == 180 then
	-- 							rot = 0
	-- 						elseif rot == 0 then
	-- 							rot = 180
	-- 						end
	-- 						conneted_at = rot
	-- 						core.log(conneted_at)
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
	-- if is_connected == true then
	-- if pointed_at_stairs == true then
	-- 	return "outer", conneted_at
	-- else
	-- return "inner", conneted_at
	-- end
	-- end
	return nil, nil
end

local function gotAngle(p, new_rot, point, hit_pos, under, this_node)
	if Utils.StringContains(this_node.description, "slab") ~= nil then
		if point.y >= hit_pos.y then
			new_rot = { x = math.rad(180), y = 0, z = 0 }
		end
		if this_node.paramtype2 == "facedir" then
			if p:get_player_control()["sneak"] == true then
				new_rot = { x = math.rad(90), y = 0, z = 0 }
			end
		end
		return new_rot
	end

	if this_node.paramtype2 == "facedir" then
		if Utils.StringContains(this_node.description, "stair") ~= nil or Utils.StringContains(this_node.name, "stair") ~= nil then
			--THIS TAKES CARE OF CORNER-type STAIRS..
			if Utils.StringContains(this_node.description, "inner") ~= nil or Utils.StringContains(this_node.description, "outer") ~= nil then
				local y = math.rad(0)
				local elsey = math.rad(270)
				new_rot = { x = 0, y = 0, z = 0 }
				if point.y >= hit_pos.y then
					new_rot = { x = math.rad(180), y = 0, z = 0 }
					y = math.rad(270)
					elsey = math.rad(180)
				end
				local facing = math.deg(quantize_direction(p:get_look_horizontal()))
				if facing == 0 then
					if hit_pos.x >= point.x then
						new_rot = { x = new_rot.x, y = y, z = 0 }
					else
						new_rot = { x = new_rot.x, y = elsey, z = 0 }
					end
					return new_rot
				end
				if facing == 90 then
					if hit_pos.z >= point.z then
						new_rot = { x = new_rot.x, y = y, z = 0 }
					else
						new_rot = { x = new_rot.x, y = elsey, z = 0 }
					end
					return new_rot
				end
				if facing == 180 then
					if hit_pos.x <= point.x then
						new_rot = { x = new_rot.x, y = y, z = 0 }
					else
						new_rot = { x = new_rot.x, y = elsey, z = 0 }
					end
					return new_rot
				end
				if facing == 270 then
					if hit_pos.z <= point.z then
						new_rot = { x = new_rot.x, y = y, z = 0 }
					else
						new_rot = { x = new_rot.x, y = elsey, z = 0 }
					end
				end
				return new_rot
			end

			--*normal stairs
			if point.y >= hit_pos.y then
				new_rot = { x = math.rad(90), y = 0, z = 0 }
			end
			if p:get_player_control()["sneak"] == true then
				local facing = math.deg(quantize_direction(p:get_look_horizontal()))
				if facing == 0 then
					if hit_pos.x >= point.x then
						new_rot = { x = 0, y = 0, z = math.rad(90) }
					else
						new_rot = { x = 0, y = 0, z = math.rad(270) }
					end
					return new_rot
				end
				if facing == 180 then
					if hit_pos.x <= point.x then
						new_rot = { x = 0, y = 0, z = math.rad(90) }
					else
						new_rot = { x = 0, y = 0, z = math.rad(270) }
					end
					return new_rot
				end
				if facing == 90 then
					if hit_pos.z >= point.z then
						new_rot = { x = 0, y = 0, z = math.rad(90) }
					else
						new_rot = { x = 0, y = 0, z = math.rad(270) }
					end
					return new_rot
				end
				if facing == 270 then
					if hit_pos.z <= point.z then
						new_rot = { x = 0, y = 0, z = math.rad(90) }
					else
						new_rot = { x = 0, y = 0, z = math.rad(270) }
					end
				end
			end
			return new_rot
		end
		if Utils.StringContains(this_node.description, "pumpkin") ~= nil or Utils.StringContains(this_node.description, "observer") ~= nil or Utils.StringContains(this_node.description, "dispenser") ~= nil or Utils.StringContains(this_node.description, "dropper") ~= nil then
			--uses the same logic as wallmounted
			if p:get_player_control()["sneak"] == true then
				new_rot = { x = 0, y = 0, z = 0 }
			else
				if under.x == hit_pos.x and under.z == hit_pos.z then
					if under.y >= hit_pos.y then
						new_rot = { x = math.rad(90), y = 0, z = 0 }
						return new_rot
					end
					new_rot = { x = math.rad(-90), y = 0, z = 0 }
				else
				end
			end
			return new_rot
		end
		-- if Utils.StringContains(this_node.description, "table") ~= nil or Utils.StringContains(this_node.description, "chest") ~= nil or Utils.StringContains(this_node.description, "barrel") ~= nil or Utils.StringContains(this_node.description, "crate") ~= nil or Utils.StringContains(this_node.description, "furnace") ~= nil or Utils.StringContains(this_node.description, "door") ~= nil or Utils.StringContains(this_node.description, "bench") ~= nil then
		-- 	--lets not get chests all funky looking
		-- return new_rot
		-- end
		if Utils.StringContains(this_node.description, "lantern") ~= nil then
			new_rot = { x = math.rad(-90), y = 0, z = 0 }
			return new_rot
		end
		if under.x == hit_pos.x and under.z == hit_pos.z then
			if under.y >= hit_pos.y then
				new_rot = { x = math.rad(180), y = 0, z = 0 }
			else
				new_rot = { x = math.rad(0), y = 0, z = 0 }
			end
		end
		if under.y == hit_pos.y then
			new_rot = { x = math.rad(90), y = 0, z = 0 }
		end
		return new_rot
		-- end
	end


	if this_node.paramtype2 == "wallmounted" then
		if under.x == hit_pos.x and under.z == hit_pos.z then
			if under.y >= hit_pos.y then
				new_rot = { x = math.rad(90), y = 0, z = 0 }
				return new_rot
			end
			new_rot = { x = math.rad(-90), y = 0, z = 0 }
		else
		end
		return new_rot
	end

	if this_node.drawtype == "raillike" then
		if under.x == hit_pos.x and under.z == hit_pos.z then
			if under.y >= hit_pos.y then
				return new_rot
			end
			new_rot = { x = math.rad(-90), y = 0, z = 0 }
		else
			new_rot = { x = math.rad(-45), y = 0, z = 0 }
		end
		return new_rot
	end

	if this_node.drawtype == "plantlike" then
		-- p_data.ghost_object:set_properties({ visual = "sprite"})
		-- if under.x == hit_pos.x and under.z == hit_pos.z then
		-- 	if under.y >= hit_pos.y then
		return new_rot
		-- 	end
		-- 	new_rot = { x = math.rad(-90), y = 0, z = 0 }
		-- else
		-- 		new_rot = { x = math.rad(-45), y = 0, z = 0 }
		-- end
	end

	return new_rot
end

local function doIt(p)
	--TODO: put all of this in a function that i can return early from
	local new_rot = { x = 0, y = 0, z = 0 }
	local p_name = p:get_player_name()
	local p_data = Player_data.getPlayer(p_name)

	--check if player has feature disabled
	if p_data.disabled then
		p_data:removePreview()
		return
	end

	local hand_item = p:get_wielded_item()
	local item_name = hand_item:get_name()

	local this_node = minetest.registered_nodes[item_name]

	if this_node == nil then
		p_data:removePreview()
		return
	else

	end

	if hand_item:is_empty() == true then
		p_data:removePreview()
	else
		if this_node ~= nil then
			p_data.node_paramtype2 = this_node.paramtype2
		end
		if this_node == nil then
			p_data:removePreview()
			return
		end
	end

	if hand_item:is_empty() == true then
		return
	end

	if p_data.only_stairs_slabs == true then
		if Utils.StringContains(this_node.description, "stairs") ~= nil or Utils.StringContains(this_node.name, "stairs") ~= nil then
		else
			p_data:removePreview()
			return
		end
	end

	local eye_height = p:get_properties().eye_height
	local player_look_dir = p:get_look_dir()
	local pos = p:get_pos():add(player_look_dir)
	local player_pos = { x = pos.x, y = pos.y + eye_height, z = pos.z }
	local player_reach_distance = reach_distance
	if core.get_modpath("mcl_gamemode") and mcl_gamemode then
		local player_gamemode = mcl_gamemode.get_gamemode(p)
		-- core.log("gamemode: "..player_gamemode)
		if core.get_modpath("mcl_meshhand") and mcl_meshhand then
			if player_gamemode == "creative" then
				player_reach_distance = tonumber(minetest.settings:get("mcl_hand_range_creative")) or 9.5
			else
				player_reach_distance = tonumber(minetest.settings:get("mcl_hand_range")) or 3.5
			end
		end
	end
	local new_pos = p:get_look_dir():multiply(player_reach_distance):add(player_pos)
	local raycast_result = minetest.raycast(player_pos, new_pos, false, false):next()

	if raycast_result then
		local hit_pos = raycast_result.above
		local under = raycast_result.under
		local point = raycast_result.intersection_point

		local face_pos = vector.subtract(hit_pos, under)
		-- local pointed_node = minetest.registered_nodes[minetest.get_node(under).name]
		local pointed_node = minetest.get_node(under)
		-- local pointed_face = raycast_result.intersection_normal
		local corner_type, snap, upside = nil, nil, nil
		if hit_pos ~= nil then
			if p_data.ghost_object == nil then
				p_data.ghost_object = minetest.add_entity(hit_pos, mod_name .. ":" .. "ghost_object")
			end
			p_data.ghost_object:set_properties({ visual = "item" })

			--lets just place the stair normally without connecting
			if p:get_player_control()["sneak"] == false then
				-- is_connected, snap = shouldConnect(hit_pos, this_node, pointed_node)
				corner_type, snap, upside = connectTo(p, hit_pos, this_node, pointed_node, under, face_pos)
			end

			if corner_type ~= nil then
				if Utils.StringContains(this_node.name, corner_type) ~= nil then
					return
				end

				local found_varient = false
				local varient_node = minetest.registered_nodes[item_name .. "_" .. corner_type]

				if varient_node == nil then
					local split_word = Utils.Split(item_name, "_")
					local combined_word = split_word[1] .. "_" .. corner_type .. "_" .. split_word[2]
					varient_node = minetest.registered_nodes[combined_word]
					if varient_node ~= nil then
						item_name = combined_word
						found_varient = true
					else
						found_varient = false
					end
				else
					item_name = item_name .. "_" .. corner_type
				end
				if varient_node ~= nil then
					this_node = varient_node
				end
				if found_varient == true then
					p_data.connected = true
				end
			else
				p_data.connected = false
			end

			-- PREVIEW TWO SLABS INTO ONE
			if Utils.StringContains(item_name, "SLAB") ~= nil then
				if Utils.StringContains(pointed_node.name, item_name) ~= nil then
					p_data.double_slab = under

					local param2 = pointed_node.param2

					if p:get_player_control()["sneak"] == false then
						--VERTICAL
						if Utils.Distance(point.x, point.y, point.z, under.x, under.y, under.z) < 0.3 then
							if param2 == 8 then
								new_rot = { x = math.rad(90), y = math.rad(180), z = new_rot.z }
								hit_pos = under
								goto override
							end
							if param2 == 17 then
								new_rot = { x = math.rad(90), y = math.rad(90), z = new_rot.z }
								hit_pos = under
								goto override
							end
							if param2 == 6 then
								new_rot = { x = math.rad(90), y = math.rad(360), z = new_rot.z }
								hit_pos = under
								goto override
							end
							if param2 == 15 then
								new_rot = { x = math.rad(90), y = math.rad(270), z = new_rot.z }
								hit_pos = under
							end
						end

						if hit_pos.x == under.x then
							if hit_pos.z == under.z then
								if Utils.Distance(point.x, point.y, point.z, under.x, under.y, under.z) < 0.4 then
									if hit_pos.y > under.y then
										hit_pos = under
										new_rot = { x = math.rad(180), y = new_rot.y, z = new_rot.z }
										-- goto skip_this
									end
									hit_pos = under
									new_rot = { x = math.rad(0), y = new_rot.y, z = new_rot.z }
									-- goto got_angle
								end
								-- goto skip_this
							end
						end
						--why was this here? this pretty much did nothing
						-- if hit_pos.y - 0.5 > under.y - 1 then
						-- 	-- goto skip_this
						-- end
					end
				end
			else
				p_data.double_slab = nil
			end
			-- ::skip_this::

			new_rot = gotAngle(p, new_rot, point, hit_pos, under, this_node)

			-- ::got_angle::


			if p_data.connected == false then
				if this_node.paramtype2 == "facedir" or this_node.paramtype2 == "4dir" or this_node.paramtype2 == "wallmounted" or this_node.drawtype == "raillike" then
					local p_rot = quantize_direction(p:get_look_horizontal())
					new_rot = { x = new_rot.x, y = p_rot + new_rot.y, z = new_rot.z }
				end
			else
				if snap ~= nil then
					-- new_rot = { x = snap[1].x + snap[2].x, y = math.rad(0),z = snap[1].z + snap[2].z }
					-- new_rot = { x = math.rad(snap[1].x + snap[2].x), y = 0,z = 0}
					-- new_rot = { x = 0, y = math.rad(snap), z = 0 }
					-- new_rot = { x = 0, y = math.rad(snap), z = 0 }
					if upside == false then
						-- core.log("THIS SHOULD BE UPSIDE DOWN")
						new_rot = { x = math.rad(180), y = math.rad(snap), z = new_rot.z }
					else
						-- core.log("THIS SHOULD BE NORMAL")
						new_rot = { x = new_rot.x, y = math.rad(snap), z = new_rot.z }
					end
				end
			end
			::override::

			p_data.rotation = new_rot
			p_data.ghost_object:set_rotation(new_rot)

			local buildable = minetest.registered_nodes[pointed_node.name].buildable_to
			if buildable ~= nil then
				if buildable == true then
					hit_pos = under
				end
			end

			if p_data.stairslike_only == true then
				if Utils.StringContains(this_node.name, "stairs") == nil or Utils.StringContains(this_node.name, "stairs") == nil then
					p_data:removePreview()
					return
				end
			end

			if p_data.smooth == true then
				p_data.ghost_object:move_to(hit_pos)
			else
				p_data.ghost_object:set_pos(hit_pos)
			end

			if this_node.drawtype == "plantlike" then
				if p_data.ghost_object:get_properties().visual ~= "sprite" then
					p_data.ghost_object:set_properties({ visual = "sprite" })
				end
				if p_data.ghost_object:get_properties().textures ~= this_node.tiles then
					p_data.ghost_object:set_properties({ textures = this_node.tiles })
					-- p_data.ghost_object:set_properties({ textures = { this_node.tiles[1] .. "^[opacity:160" } })
				end
			else
				p_data.ghost_object:set_properties({ wield_item = item_name })
			end
		end
	else
		p_data:removePreview()
	end
end

-- Function to perform raycast and handle the result
local function perform_raycast()
	local player = minetest.get_connected_players()
	if #player > 0 then
		for _, p in pairs(player) do
			doIt(p)
		end
	end
end


local tick = 0.0
minetest.register_globalstep(function(dtime)
	perform_raycast()
	tick = tick + 0.5
	if tick == 1 then
		ghost_objectAnimation()
		tick = 0
	end
end)

minetest.register_on_leaveplayer(function(ObjectRef, timed_out)
	--remove the object when the player leaves
	for i, p in ipairs(Player_data) do
		if p.player_name == ObjectRef:get_player_name() then
			-- p.ghost_object:remove()
			-- p.ghost_object= nil
			table.remove(Player_data, i)
		end
	end
end)

if dev_mode == true then
	core.register_on_punchnode(function(pos, node, puncher, pointed_thing)
		core.log("what is this" .. dump(node))
	end)
end
