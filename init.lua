local mod_name = "placement_preview"

----LEAVE THIS HERE----
--TODO: setup some type of api for mod devs
--TODO: add ingame cmd for players to edit what orientaion behavior a node should have()

--NOTE: Why is it by default only work for stairs and slabs? well, because constantly seeing a preview is kinda annoying specially when this games lets you have building items in your hotbar
--DONE: the oneplace should only function when its stairs or slabs
--exmaple: its rotating torches
--DONE: made the visual possibly animate
--DONE: remove object when the world end
--DONE: set for multiplayer
--DONE: maybe make it so slabs can become walls.. hold shift?
--hold sneak to place as wall
--DONE: on place, is not respecting the preview position!!
--DONE: player has unlimited full nodes
--DONE(made it glow instead): figure out if i can make it slightly transparent
--DONE: add command to enable and disable the feature
--DONE(getting there, logs not being placed right): get correct placement preview depending on paramtyp2
--use the same horizontal rotatoin that ive been using.. if if point under Y level [x,z] are equal then place facing up/down..
--otherwise point to sides
--can use that same logic for wallmounted
--DONE: upside down stair are not the right texture orientation
--DONE: ignore nodes with buildable tag
--DONE: add support for type wallmounted
--TODO(maybe another time): combine slabs?? to full node, if the placed node is the same type show a preview in the same location but with the preview being flipped
--TODO: export function to enable and disable feature
--TODO: add an option to enable and disable preview of non- stairs/slab nodes (default=disabled)
--TODO: options to snap to pos node or glide [set_pos or move_to]
--TODO: figure out how to do placement for inner/outer corner stairs
--TODO: add support for doors
--TODO(done with facedir): instead of checking a nodes names check for facedir and 4dir
--FIXME: mcl daylight-sensor,and carpets looking goofy

--FIXME: need to ignore the player's own hitbox. gets in the way when trying to "preview" placement below the player.
--FIXME: look position is not alawys where it should be.. if they intersection is too close it will miss the node git the next.

--FIXME(mcl may cause problems): let all nodes be able to do full rotations onless specified.. (reason: mcl dispenser.. etc.)
--FIXME: (mcl lily pads, should show preview on top of water)
--FIXME: mcl lantern not in correct orientation
--FIXME(YES to this): a good amount of node's orientation should be similiar to tree/log types
--example: mcl piston, end rod, grindstone
--FIXME:mcl whatever the player head node is.. it needs to preview to the players rotatoin

--DOTHIS: facedir will act like logs or nodes with invs. for orientation difference check if the node includes "stair" in name
-- add arch also be stair support

----===============----


local glow_amount = 4
local RayDistance = 3.0 -- Adjust as needed -- this should actaully just be the player's reach distance
-- local other_nodes = true --false, only preview stairs & slabs. true, all

---@type table
local player_data = {}

local function ghost_objectAnimation()
	for _, p in ipairs(player_data) do
		if p.ghost_object ~= nil then
			local size = p.ghost_object:get_properties().visual_size
			local amount = 0
			local y_amount = 0
			if p.ghost_object_grow == true then
				if size.x <= 0.6 then
					amount = 0.02
					y_amount = 0.01
				else
					p.ghost_object_grow = false
				end
			end
			if p.ghost_object_grow == false then
				if size.x >= 0.58 then
					amount = -0.02
					y_amount = -0.01
				else
					p.ghost_object_grow = true
				end
			end
			local new_size = { x = size.x + amount, y = size.y + y_amount, z = size.z + amount }
			p.ghost_object:set_properties({ visual_size = new_size })
		end
	end
end

function player_data.addPlayer(name)
	local data = { player_name = name, ghost_object = nil, ghost_object_grow = true, rotation = { x = 0, y = 0, z = 0 }, disabled = false, node_paramtype2 = nil, double_slab = nil }
	table.insert(player_data, data)
	return data
end

---@alias data table

---@return data
function player_data.getPlayer(name)
	for _, p in ipairs(player_data) do
		if p.player_name == name then
			return p
		end
	end
	return player_data.addPlayer(name)
end

local function splitString(full_string, sub)
	local out = {}
	local i, _ = string.find(full_string, sub)
	if i == nil then
		return nil
	end
	for x = 0, i - 2, 1 do
		out[x] = string.sub(full_string, x, x)
	end
	return table.concat(out)
end


local function stringContains(str, find)
	str = string.upper(str)
	find = string.upper(find)
	local i, _ = string.find(str, find)
	return i
end

minetest.register_chatcommand("placement_preview", {
	params = "[on|off] or [enable|disable] or [true|false]",
	description = "disable or enable the placement preview",
	privs = {},
	func = function(name, param)
		local player = player_data.getPlayer(name)
		local _, fields = param:gsub("%S+", "")
		minetest.debug("this is the command: " .. param .. " " .. #param)
		if fields > 1 then
			minetest.chat_send_player(name, minetest.colorize("red", "example: /placement_preview off"))
			return
		end
		if param == "on" or param == "true" or param == "enable" then
			player.disabled = false
			minetest.chat_send_player(name, minetest.colorize("cyan", "placement_preview has been enable"))
		elseif param == "off" or param == "false" or param == "disable" then
			player.disabled = true
			minetest.chat_send_player(name, minetest.colorize("cyan", "placement_preview has been disabled"))
		elseif param == "help" then
			minetest.chat_send_player(name,
				minetest.colorize("yellow", "try /placement_preview [on|off] or [enable|disable] or [true|false]"))
		else
			minetest.chat_send_player(name, minetest.colorize("red", "You may be brain dead.. example: /placement_preview off"))
		end
	end,

})

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	-- local placed_node = minetest.registered_nodes[newnode.name]
	-- minetest.debug("placed param2: "..placed_node.paramtype2)
	-- if oldnode.paramtype2 == "facedir" then
	local p_data = player_data.getPlayer(placer:get_player_name())

	-- if p_data.double_slab ~= nil then
	-- 	local full_node_name = splitString(newnode.name,"slab")

	-- 	local full_node = minetest.registered_nodes[full_node_name]
	-- 	minetest.debug("full name is: "..full_node_name)
	-- 	minetest.remove_node(pos)
	-- 	minetest.swap_node(p_data.double_slab,full_node)

	-- 	return
	-- end
	if p_data.node_paramtype2 == nil or p_data.node_paramtype2 == "wallmounted" or p_data.node_paramtype2 == "none" then
		return
		-- minetest.debug("node_paramtype2: "..p_data.node_paramtype2)
	end
	-- for i,v in pairs(newnode) do
	-- 	minetest.debug("on place: "..i.."-"..v)
	-- end
	if p_data.node_paramtype2 == "facedir" then
		-- if stringContains(newnode.name, "STAIR") ~= nil or stringContains(newnode.name, "STAIRS") ~= nil then
		local face = 0
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

		local amount = 90

		local vert_slab = false

		if placer:get_player_control()["sneak"] == true then
			--if sneaking leave at previous amount.. we are making walls
			if stringContains(newnode.name, "SLAB") ~= nil or stringContains(newnode.name, "log") ~= nil or stringContains(newnode.name, "tree") ~= nil or stringContains(newnode.name, "trunk") ~= nil then
				vert_slab = true
				-- minetest.debug("should be vertical")
			else
				-- if stringContains(newnode.name, "STAIR") ~= nil or stringContains(newnode.name, "STAIRS") ~= nil then
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
			if stringContains(newnode.name, "SLAB") ~= nil then
				amount = 180
			end
		end

		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 0 then
			if vert_slab == true then
				face = 8
			elseif stringContains(newnode.name, "SLAB") ~= nil then
				face = 20
			else
				face = 8
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 90 then
			if vert_slab == true then
				face = 15
			elseif stringContains(newnode.name, "SLAB") ~= nil then
				face = 21
			else
				face = 15
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 180 then
			if vert_slab == true then
				face = 6
			elseif stringContains(newnode.name, "SLAB") ~= nil then
				face = 22
			else
				face = 6
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 270 then
			if vert_slab == true then
				-- face = 20
				face = 17
			elseif stringContains(newnode.name, "SLAB") ~= nil then
				face = 23
			else
				-- face = 23
				face = 17
			end
		end

		::done::
		newnode.param2 = face
		minetest.swap_node(pos, newnode)
		-- minetest.set_node(pos, newnode)
	else
		return
	end
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
	tiles = { "default_cobble.png" },
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

minetest.register_node(mod_name .. ":" .. "dev_node_slab", {
	description = "dev slab[get orientation]",
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{ -0.5, -0.5, -0.5, 0.5, 0.0, 0.5 },
		}

	},
	tiles = { "default_cobble.png" },
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



-- Function to perform raycast and handle the result
local function perform_raycast()
	local player = minetest.get_connected_players()
	if #player > 0 then
		for _, p in pairs(player) do
			local p_name = p:get_player_name()
			local p_data = player_data.getPlayer(p_name)

			--check if player has feature disabled
			if p_data.disabled == true then
				if p_data.ghost_object ~= nil then
					p_data.ghost_object:remove()
					p_data.ghost_object = nil
				end
				goto continue
			end

			local hand_item = p:get_wielded_item()
			local item_name = hand_item:get_name()

			local this_node = minetest.registered_nodes[hand_item:get_name()]

			if hand_item:is_empty() == true then
				if p_data.ghost_object ~= nil then
					p_data.ghost_object:remove()
					p_data.ghost_object = nil
				end
			else
				--check if hand_item is a node
				if this_node ~= nil then
					p_data.node_paramtype2 = this_node.paramtype2
				end
				-- if this_node == nil or this_node.paramtype2 == "wallmounted" or this_node.paramtype2 == "none" then
				if this_node == nil then
					-- minetest.debug("yea this is broken")
					if p_data.ghost_object ~= nil then
						p_data.ghost_object:remove()
						p_data.ghost_object = nil
					end
					goto continue
				end
			end

			--save the node's paramtype2 for later use

			local eye_height = p:get_properties().eye_height
			local player_look_dir = p:get_look_dir()
			local pos = p:get_pos():add(player_look_dir)
			local player_pos = { x = pos.x, y = pos.y + eye_height, z = pos.z }
			local new_pos = p:get_look_dir():multiply(RayDistance):add(player_pos)
			local raycast_result = minetest.raycast(player_pos, new_pos, false, false):next()

			if raycast_result then
				if hand_item:is_empty() == true then
					goto continue
				end

				local hit_pos = raycast_result.above
				local under = raycast_result.under
				local point = raycast_result.intersection_point
				-- local pointed_node = minetest.registered_nodes[minetest.get_node(under).name]
				local pointed_node = minetest.get_node(under)
				-- local pointed_face = raycast_result.intersection_normal
				if hit_pos ~= nil then
					if p_data.ghost_object == nil then
						p_data.ghost_object = minetest.add_entity(hit_pos, mod_name .. ":" .. "ghost_object")
					end
					p_data.ghost_object:set_properties({ visual = "item" })


					local new_rot = { x = 0, y = 0, z = 0 }


					-- PREVIEW TWO SLABS INTO ONE
					-- if p:get_player_control()["sneak"] == false then
					if stringContains(item_name, "SLAB") ~= nil then
						if pointed_node.name == item_name then
							p_data.double_slab = under
							-- for i, v in pairs(pointed_node) do
							-- 	minetest.debug(minetest.colorize("yellow", string.format("here: %s", i)))
							-- end
							-- minetest.debug(minetest.colorize("yellow",
							-- 	string.format("%s:%s [%s]", item_name, pointed_node.name, pointed_node.param2)))

							local param2 = pointed_node.param2

							--HORIZONTAL
							if param2 == 0 or param2 == 1 or param2 == 2 or param2 == 3 then
								if p:get_player_control()["sneak"] == true then
									goto override
								end
								hit_pos = under
								new_rot = { x = math.rad(180), y = new_rot.y, z = new_rot.z }
								goto skip_this
							end
							if param2 == 20 or param2 == 23 or param2 == 22 or param2 == 21 then
								if p:get_player_control()["sneak"] == true then
									goto override
								end
								hit_pos = under
								new_rot = { x = math.rad(0), y = new_rot.y, z = new_rot.z }
								goto skip_this
							end

							--VERTICAL
							if p:get_player_control()["sneak"] == true then
								goto skip_this
							end
							if param2 == 8 then
								new_rot = { x = math.rad(90), y = math.rad(180), z = new_rot.z }
							end
							if param2 == 17 then
								new_rot = { x = math.rad(90), y = math.rad(90), z = new_rot.z }
							end
							if param2 == 6 then
								new_rot = { x = math.rad(90), y = math.rad(360), z = new_rot.z }
							end
							if param2 == 15 then
								new_rot = { x = math.rad(90), y = math.rad(270), z = new_rot.z }
							end
							hit_pos = under
							goto override

							-- goto got_angle
						end
					else
							p_data.double_slab = nil
					end
					::skip_this::

					if stringContains(item_name, "chest") ~= nil or stringContains(item_name, "barrel") ~= nil or stringContains(item_name, "crate") ~= nil or stringContains(item_name, "furnace") ~= nil then
						--lets not get chests all funky looking
						goto got_angle
					end
					if stringContains(item_name, "log") ~= nil or stringContains(item_name, "tree") ~= nil or stringContains(item_name, "trunk") ~= nil then
						-- new_rot = { x = math.rad(180), y = 0, z = 0 }
						if under.y == hit_pos.y then
							new_rot = { x = math.rad(90), y = 0, z = 0 }
						end
						goto got_angle
					end

					if this_node.paramtype2 == "wallmounted" then
						if under.x == hit_pos.x and under.z == hit_pos.z then
							if under.y >= hit_pos.y then
								new_rot = { x = math.rad(90), y = 0, z = 0 }
								goto got_angle
							end
							new_rot = { x = math.rad(-90), y = 0, z = 0 }
						else
						end
						goto got_angle
					end

					if this_node.drawtype == "raillike" then
						if under.x == hit_pos.x and under.z == hit_pos.z then
							if under.y >= hit_pos.y then
								goto got_angle
							end
							new_rot = { x = math.rad(-90), y = 0, z = 0 }
						else
							new_rot = { x = math.rad(-45), y = 0, z = 0 }
						end
						goto got_angle
					end

					if this_node.drawtype == "plantlike" then
						-- minetest.debug("we have a plantlike")
						-- p_data.ghost_object:set_properties({ visual = "sprite"})
						-- if under.x == hit_pos.x and under.z == hit_pos.z then
						-- 	if under.y >= hit_pos.y then
						-- 		goto got_angle
						-- 	end
						-- 	new_rot = { x = math.rad(-90), y = 0, z = 0 }
						-- else
						-- 		new_rot = { x = math.rad(-45), y = 0, z = 0 }
						-- end
						goto got_angle
					end

					if p:get_player_control()["sneak"] == false then
						if point.y >= hit_pos.y then
							-- minetest.debug("yes this is this!!!")
							if this_node.paramtype2 == "facedir" or this_node.paramtype2 == "leveled" then
								--lets make make it a wall
								new_rot = { x = math.rad(90), y = 0, z = 0 }
								if stringContains(item_name, "SLAB") ~= nil then
									new_rot = { x = math.rad(180), y = 0, z = 0 }
								end
							end
						end
					elseif this_node.paramtype2 == "facedir" then
						-- if stringContains(item_name, "STAIR") ~= nil or stringContains(item_name, "STAIRS") ~= nil then
						if stringContains(item_name, "SLAB") ~= nil then
							new_rot = { x = math.rad(90), y = 0, z = 0 }
							goto got_angle
						end
						if stringContains(item_name, "TRAPDOOR") ~= nil then
							goto got_angle
						end

						local facing = math.deg(quantize_direction(p:get_look_horizontal()))
						-- local facing = quantize_direction(pointed_face)
						if facing == 0 then
							if hit_pos.x >= point.x then
								new_rot = { x = 0, y = 0, z = math.rad(90) }
							else
								new_rot = { x = 0, y = 0, z = math.rad(270) }
							end
							goto got_angle
						end
						if facing == 180 then
							if hit_pos.x <= point.x then
								new_rot = { x = 0, y = 0, z = math.rad(90) }
							else
								new_rot = { x = 0, y = 0, z = math.rad(270) }
							end
							goto got_angle
						end
						if facing == 90 then
							if hit_pos.z >= point.z then
								new_rot = { x = 0, y = 0, z = math.rad(90) }
							else
								new_rot = { x = 0, y = 0, z = math.rad(270) }
							end
							goto got_angle
						end
						if facing == 270 then
							if hit_pos.z <= point.z then
								new_rot = { x = 0, y = 0, z = math.rad(90) }
							else
								new_rot = { x = 0, y = 0, z = math.rad(270) }
							end
						end
					end
					::got_angle::


					if this_node.paramtype2 == "facedir" or this_node.paramtype2 == "4dir" or this_node.paramtype2 == "wallmounted" or this_node.drawtype == "raillike" then
						local p_rot = quantize_direction(p:get_look_horizontal())
						-- local p_rot = quantize_direction(pointed_face)
						new_rot = { x = new_rot.x, y = p_rot + new_rot.y, z = new_rot.z }
					end
					::override::

					p_data.rotation = new_rot
					p_data.ghost_object:set_rotation(new_rot)

					--DO: switch find strng to get paramtype2. but also check again to find slab(so it can still be placed as walls)
					local buildable = minetest.registered_nodes[pointed_node.name].buildable_to
					-- minetest.debug(string.format("%s's paramtype2: %s", pointed_node.name, pointed_node.paramtype2))
					if buildable ~= nil then
						if buildable == true then
							hit_pos = under
						end
					end
					p_data.ghost_object:set_pos(hit_pos)
					if this_node.drawtype == "plantlike" then
						-- p_data.ghost_object:set_properties({ drawtype = "sprite"})
						if p_data.ghost_object:get_properties().visual ~= "sprite" then
							p_data.ghost_object:set_properties({ visual = "sprite" })
						end
						if p_data.ghost_object:get_properties().textures ~= this_node.tiles then
							p_data.ghost_object:set_properties({ textures = this_node.tiles })
						end
					else
						p_data.ghost_object:set_properties({ wield_item = item_name })
					end


					-- local rotate_this = false
					-- if stringContains(item_name, "STAIR") ~= nil then
					-- 	rotate_this = true
					-- 	goto we_preview
					-- end
					-- if stringContains(item_name, "STAIRS") ~= nil then
					-- 	rotate_this = true
					-- 	goto we_preview
					-- end
					-- if stringContains(item_name, "SLAB") ~= nil then
					-- 	rotate_this = true
					-- 	goto we_preview
					-- end
					-- ::we_preview::
					-- if rotate_this == false then
					-- 	goto continue
					-- end
				end
			else
				if p_data.ghost_object ~= nil then
					p_data.ghost_object:remove()
					p_data.ghost_object = nil
				end
				-- minetest.debug("Raycast did not hit anything")
			end
			::continue::
		end
	end
end

-- Function to continuously perform raycast
local function continuous_raycast()
	-- Perform the initial raycast
	perform_raycast()
	ghost_objectAnimation()
	-- Schedule the next raycast after a delay (e.g., every 0.1 seconds)
	minetest.after(0.1, continuous_raycast)
end

-- Start the continuous raycasting process
continuous_raycast()

minetest.register_on_leaveplayer(function(ObjectRef, timed_out)
	--remove the object when the player leaves
	for i, p in ipairs(player_data) do
		if p.player_name == ObjectRef:get_player_name() then
			-- p.ghost_object:remove()
			-- p.ghost_object= nil
			table.remove(player_data, i)
		end
	end
end)


-- minetest.register_on_shutdown(function()
-- 	--remove the object at shutdown
-- 	for _, p in ipairs(player_data) do
-- 		p.ghost_object:remove()
-- 		p.ghost_object= nil
-- 	end
-- end)
