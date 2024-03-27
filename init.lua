local mod_name = "placement_preview"

----LEAVE THIS HERE----
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
--TODO(maybe another time): combine slabs?? to full node, if the placed node is the same type show a preview in the same location but with the preview being flipped
--TODO: export function to enable and disable feature
--TODO: add an option to enable and disable preview of non- stairs/slab nodes (default=disabled)
--TODO: options to snap to pos node or glide [set_pos or move_to]
--TODO: figure out how to do placement for inner/outer corner stairs
--FIXME: need to ignore the player's own hitbox. gets in the way when trying to "preview" placement below the player.
--FIXME: look position is not alawys where it should be.. if they intersection is too close it will miss the node git the next.
--FIXME: get correct placement preview depending on paramtyp2
----===============----


local RayDistance = 3.0  -- Adjust as needed -- this should actaully just be the player's reach distance
local other_nodes = true --false, only preview stairs & slabs. true, all

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
	local data = { player_name = name, ghost_object = nil, ghost_object_grow = true, rotation = { x = 0, y = 0, z = 0 }, disabled = false }
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
	if stringContains(newnode.name, "STAIR") ~= nil or stringContains(newnode.name, "STAIRS") ~= nil then
		local p_data = player_data.getPlayer(placer:get_player_name())
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
			if stringContains(newnode.name, "SLAB") ~= nil then
				vert_slab = true
				-- minetest.debug("should be vertical")
			else
				if stringContains(newnode.name, "STAIR") ~= nil or stringContains(newnode.name, "STAIRS") ~= nil then
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
			else
				face = 20
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 90 then
			if vert_slab == true then
				face = 15
			else
				face = 21
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 180 then
			if vert_slab == true then
				face = 6
			else
				face = 22
			end
			goto done
		end
		if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 270 then
			if vert_slab == true then
				-- face = 20
				face = 17
			else
				face = 23
			end
		end

		::done::
		newnode.param2 = face
		minetest.swap_node(pos, newnode)
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
	glow = 3,
	static_save = false,
	physical = false,
	pointable = false,
	shaded = false,
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
			if hand_item:is_empty() == true then
				if p_data.ghost_object ~= nil then
					p_data.ghost_object:remove()
					p_data.ghost_object = nil
				end
			else
				--check if hand_item is a node
				if minetest.registered_nodes[hand_item:get_name()] == nil then
					if p_data.ghost_object ~= nil then
						p_data.ghost_object:remove()
						p_data.ghost_object = nil
					end
					goto continue
				end
			end

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
				-- local under = raycast_result.under
				local point = raycast_result.intersection_point
				if hit_pos ~= nil then
					if p_data.ghost_object == nil then
						p_data.ghost_object = minetest.add_entity(hit_pos, mod_name .. ":" .. "ghost_object")
					end

					local new_rot = { x = 0, y = 0, z = 0 }
					if p:get_player_control()["sneak"] == false then
						if point.y >= hit_pos.y then
							if stringContains(item_name, "STAIR") ~= nil then
								new_rot = { x = math.rad(90), y = 0, z = 0 }
							end
							if stringContains(item_name, "STAIRS") ~= nil then
								new_rot = { x = math.rad(90), y = 0, z = 0 }
							end
							--lets make make it a wall
							if stringContains(item_name, "SLAB") ~= nil then
								new_rot = { x = math.rad(180), y = 0, z = 0 }
							end
						end
					else
						if stringContains(item_name, "SLAB") ~= nil then
							new_rot = { x = math.rad(90), y = 0, z = 0 }
							goto got_angle
						end
						if stringContains(item_name, "STAIR") ~= nil or stringContains(item_name, "STAIRS") ~= nil then
							local facing = math.deg(quantize_direction(p:get_look_horizontal()))
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
					end

					-- preview two slabs into one
					-- if p:get_player_control()["sneak"] == false then
					-- 	if stringContains(item_name, "SLAB") ~= nil then
					-- 		minetest.debug("this is a slab")
					-- 		local under_name = minetest.get_node(under).name
					-- 		minetest.debug("names are: " .. item_name .. " & " .. under_name)
					-- 		if under_name == item_name then
					-- 			hit_pos = under
					-- 		end
					-- 	end
					-- end

					--only preview stairs and slabs
					if other_nodes == false then
						local not_what_im_looking_for = true
						if stringContains(item_name, "STAIR") ~= nil then
							not_what_im_looking_for = false
						end
						if stringContains(item_name, "STAIRS") ~= nil then
							not_what_im_looking_for = false
						end
						if stringContains(item_name, "SLAB") ~= nil then
							not_what_im_looking_for = false
						end
						if not_what_im_looking_for == true then
							if p_data.ghost_object ~= nil then
								p_data.ghost_object:remove()
								p_data.ghost_object = nil
							end
							goto continue
						end
					end

					p_data.ghost_object:set_pos(hit_pos)
					p_data.ghost_object:set_properties({ wield_item = item_name })


					local rotate_this = false
					if stringContains(item_name, "STAIR") ~= nil then
						rotate_this = true
						goto we_preview
					end
					if stringContains(item_name, "STAIRS") ~= nil then
						rotate_this = true
						goto we_preview
					end
					if stringContains(item_name, "SLAB") ~= nil then
						rotate_this = true
						goto we_preview
					end
					::we_preview::
					if rotate_this == false then
						goto continue
					end

					local p_rot = quantize_direction(p:get_look_horizontal())
					new_rot = { x = new_rot.x, y = p_rot + new_rot.y, z = new_rot.z }
					p_data.rotation = new_rot
					p_data.ghost_object:set_rotation(new_rot)

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
