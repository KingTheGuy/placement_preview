--DONE: the oneplace should only function when its stairs or slabs
--exmaple: its rotating torches
--DONE: made the visual possibly animate
--DONE: remove object when the world end
--DONE: set for multiplayer

--TODO(.): figure out if i can make it slightly transparent

--TODO: maybe make it so slabs can become walls.. hold shift?
--hold sneak to place as wall
--TODO: combine slabs?? to full node

--TODO: add command to enable and disable the feature
--TODO: export function to enable and disable feature
--TODO: add an option to enable and disable none stairs/slab nodes (default=disabled)
--TODO: options to snap at node or glide [set_pos or move_to]

--TODO: figure out how to place angled stairs
--FIXME: the player's hitbox gets in the way


local mod_name = "sense"


local RayDistance = 3.0 -- Adjust as needed

-- local rotation = { x = 0, y = 0, z = 0 }
-- local ghost_object = nil

--contains player_name ghost_object rotation

---@type table
local player_data = {}

local function ghost_objectAnimation()
	for _, p in ipairs(player_data) do
		if p.ghost_object ~= nil then
			local size = p.ghost_object:get_properties().visual_size
			local amount = 0
			if p.ghost_object_grow == true then
				if size.y <= 0.6 then
					amount = 0.02
				else
					p.ghost_object_grow = false
				end
			end
			if p.ghost_object_grow == false then
				if size.y >= 0.58 then
					amount = -0.02
				else
					p.ghost_object_grow = true
				end
			end
			local new_size = { x = size.x + amount, y = size.y + amount, z = size.z + amount }
			p.ghost_object:set_properties({ visual_size = new_size })
		end
	end
end

function player_data.addPlayer(name)
	local data = { player_name = name, ghost_object = nil, ghost_object_grow = true, rotation = { x = 0, y = 0, z = 0 } }
	table.insert(player_data, data)
	return data
end

---@alias data table

---@return data
function player_data.getPlayer(name)
	-- if #player_data <= 0 then
	-- 	return player_data.addPlayer(name)
	-- end
	-- minetest.debug("player_data size: "..#player_data)
	for _, p in ipairs(player_data) do
		if p.player_name == name then
			return p
		end
	end
	return player_data.addPlayer(name)
end

minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if string.match(string.upper(newnode.name), "SLAB") == nil or string.match(string.upper(newnode.name), "STAIRS") == nil then
		return true
	end

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
	if string.match(string.upper(newnode.name), "SLAB") then
		amount = 180
	end


	if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 0 then
		face = 20
	end
	if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 90 then
		face = 21
	end
	if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 180 then
		face = 22
	end
	if math.deg(p_data.rotation.x) == amount and math.deg(p_data.rotation.y) == 270 then
		face = 23
	end

	newnode.param2 = face
	minetest.swap_node(pos, newnode)
end)


minetest.register_entity(mod_name .. ":" .. "ghost_object", {
	initial_properties = {
		visual = "item",
	},
	wield_item = "default:cobble",
	visual_size = { x = 0.6, y = 0.6, z = 0.6 },
	collisionbox = { -0.2, -0.2, -0.2, 0.2, 0.2, 0.2 }, -- default
	-- textures = {
	-- 	"default_cobble.png",
	-- 	"default_cobble.png",
	-- 	"default_cobble.png",
	-- 	"default_cobble.png",
	-- 	"default_cobble.png",
	-- 	"default_cobble.png",
	-- },
	static_save = false,
	physical = false,
	pointable = false,
	shaded = true,
  backface_culling = false,
	use_texture_alpha = true,

	-- on_activate = function(self, staticdata, dtime_s)
	-- 	self.object:remove()
	-- end,

})

minetest.register_node(mod_name .. ":" .. "frame_node_stairs", {
	description = "a frame stair",
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
})

minetest.register_node(mod_name .. ":" .. "frame_node_slab", {
	description = "a frame slab",
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

	-- on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
	-- 	-- local new_node = minetest.registered_nodes[node.name]
	-- 	-- minetest.debug("node name: "..new_node.name)
	-- 	-- new_node.param2 = node.param2 + 1
	-- 	node.param2 = node.param2 + 1
	-- 	if node.param2 >= 24 then
	-- 		node.param2 = 0
	-- 	end
	-- 	minetest.debug("param2 is: " .. node.param2)

	-- 	-- local new_pos = {x=pos.x,y=pos.y+1,z=pos.z}
	-- 	minetest.swap_node(pos, node)
	-- end,
	-- on_deactivate = function(self, removal) 
	-- 	for _, p in ipairs(player_data) do
	-- 		if p.ghost_object == self.object then
	-- 			p.ghost_object = nil
	-- 		end
	-- 	end
	-- end,
})



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

-- Function to perform raycast and handle the result
local function perform_raycast()
	local player = minetest.get_connected_players()
	if #player > 0 then
		for _, p in pairs(player) do
			local p_name = p:get_player_name()
			local p_data = player_data.getPlayer(p_name)
			-- minetest.debug(string.format("%s with %s",p_data.player_name,p_data.ghost_object))
			local hand_item = p:get_wielded_item()
			local item_name = hand_item:get_name()
			-- minetest.debug("item name: " .. hand_item:get_name())
			if hand_item:is_empty() == true then
				if p_data.ghost_object ~= nil then
					p_data.ghost_object:remove()
					p_data.ghost_object = nil
				end
			else
				if minetest.registered_nodes[hand_item:get_name()] == nil then
					if p_data.ghost_object ~= nil then
						p_data.ghost_object:remove()
						p_data.ghost_object = nil
					end
					goto continue
				end
			end
			-- minetest.debug(p:get_pos())
			local eye_height = p:get_properties().eye_height
			local player_look_dir = p:get_look_dir()
			local pos = p:get_pos():add(player_look_dir)
			-- local player_pos = { x = pos.x, y = pos.y + 1.5, z = pos.z }
			local player_pos = { x = pos.x, y = pos.y + eye_height, z = pos.z }
			local new_pos = p:get_look_dir():multiply(RayDistance):add(player_pos)
			local raycast_result = minetest.raycast(player_pos, new_pos, true, false):next()

			-- minetest.debug("in hand: " .. hand_item:get_name())
			-- for i, v in pairs(hand_item:get_meta():to_table()) do
			-- 	minetest.debug(i .. " " .. type(v))
			-- 	for x, _ in pairs(v) do
			-- 		minetest.debug("wtf is this: ", x)
			-- 	end
			-- end

			if string.match(string.upper(item_name), "STAIR") or string.match(string.upper(item_name), "STAIRS") or string.match(string.upper(item_name), "SLAB") then
			else
				--if not slabs or stars.. i dont want the preview
				if p_data.ghost_object ~= nil then
					p_data.ghost_object:remove()
					p_data.ghost_object = nil
				end
				goto continue
			end

			if raycast_result then
				if hand_item:is_empty() == true then
					goto continue
				end
				-- minetest.debug(raycast_result.type)
				-- local hit_pos = raycast_result.intersection_point --gets the absolute pos [float]
				local hit_pos = raycast_result.above
				-- minetest.debug(hit_pos)
				local point = raycast_result.intersection_point
				-- minetest.debug("point: " .. vector.to_string(point))
				if hit_pos ~= nil then
					if p_data.ghost_object == nil then
						p_data.ghost_object = minetest.add_entity(hit_pos, mod_name .. ":" .. "ghost_object")
						-- ghost_object = minetest.add_entity(hit_pos, mod_name .. ":" .. "ghost_object")
					end
					-- local texture = ""
					-- local split_index = string.find(item_name, ":") + 1
					-- for x = split_index, #hand_item:get_name(), 1 do
					-- 	texture = texture .. string.sub(hand_item:get_name(), x, x)
					-- end
					-- texture = "default_" .. texture .. ".png^[brighten"
					-- p_data.ghost_object:move_to(hit_pos)
					p_data.ghost_object:set_pos(hit_pos)
					p_data.ghost_object:set_properties({ wield_item = item_name })
					-- p_data.ghost_object:set_properties({
					-- 	wield_item = minetest.itemstring_with_color(hand_item:get_name(),
					-- 		"#a7d5d900")
					-- })
					local new_rot = { x = 0, y = 0, z = 0 }
					if point.y >= hit_pos.y then
						if string.match(string.upper(item_name), "STAIR") then
							new_rot = { x = math.rad(90), y = 0, z = 0 }
						end
						if string.match(string.upper(item_name), "STAIRS") then
							new_rot = { x = math.rad(90), y = 0, z = 0 }
						end
						if string.match(string.upper(item_name), "SLAB") then
							new_rot = { x = math.rad(180), y = 0, z = 0 }
						end
					end

					local p_rot = quantize_direction(p:get_look_horizontal())
					new_rot = { x = new_rot.x, y = p_rot, z = 0 }
					p_data.rotation = new_rot
					p_data.ghost_object:set_rotation(new_rot)
					-- minetest.debug(string.format("placed_node rotation: %s,%s,%s", math.deg(rotation.x), math.deg(rotation.y),math.deg(rotation.z)))

					-- ghost_node:set_properties({ textures = new_texture[1].."^[brighten"})
					-- ghost_node:set_properties({ wield_item = hand_item:get_name()})
				end
				-- for i,v in pairs(raycast_result) do
				--   minetest.debug(i .." ".. type(v))
				-- end
				-- minetest.debug("type: "..raycast_result.type) --NOTE: this how i check if its an object
				-- if raycast_result.type == "object" then
				-- minetest.debug("rotation: "..raycast_result.ref:get_yaw())
				-- minetest.debug("rotation: "..vector3ToString(raycast_result.ref:get_pos()))
				-- end
				-- minetest.debug("---}")

				-- for node in pairs(ALL_THE_NODES) do
				--   if string.find(node,"chest") then
				--     minetest.debug("here is a node: "..node)
				--     minetest.debug(minetest.registered_nodes[node].on_rightclick(self, clicker))
				--   end
				-- end


				-- minetest.debug(hit_pos)
			else
				if p_data.ghost_object ~= nil then
					p_data.ghost_object:remove()
					p_data.ghost_object = nil
				end
				-- minetest.debug("Raycast did not hit anything")
			end
			::continue::
		end
		-- ::continue::
		-- return
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
			table.remove(player_data,i)
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
