-- a Tunnel Boring Machine

tbm = {}

-- offsets to determine block positions
-- access as [facedir][y][x].X for X offset from current position
-- Y for Y offset from current position and Z for Z offset etc.
-- This is a easy way to determine the 4x4 box that should be
-- mined from the current position based on the current facedir
tbm.offsets = { -- facedir indexed (+1)
	{ -- facedir = 0
		{ -- first line
			{ X = -1, Y =  2, Z =  1 },
			{ X =  0, Y =  2, Z =  1 },
			{ X =  1, Y =  2, Z =  1 }
		},
		{ -- second line
			{ X = -1, Y =  1, Z =  1 },
			{ X =  0, Y =  1, Z =  1 },
			{ X =  1, Y =  1, Z =  1 }
		},
		{ -- third line
			{ X = -1, Y =  0, Z =  1 },
			{ X =  0, Y =  0, Z =  1 },
			{ X =  1, Y =  0, Z =  1 }
		},
		{ -- forth line
			{ X = -1, Y = -1, Z =  1 },
			{ X =  0, Y = -1, Z =  1 },
			{ X =  1, Y = -1, Z =  1 }
		}
	},
	{ -- facedir = 1
		{ -- first line
			{ X =  1, Y =  2, Z = -1 },
			{ X =  1, Y =  2, Z =  0 },
			{ X =  1, Y =  2, Z =  1 }
		},
		{ -- second line
			{ X =  1, Y =  1, Z = -1 },
			{ X =  1, Y =  1, Z =  0 },
			{ X =  1, Y =  1, Z =  1 }
		},
		{ -- third line
			{ X =  1, Y =  0, Z = -1 },
			{ X =  1, Y =  0, Z =  0 },
			{ X =  1, Y =  0, Z =  1 }
		},
		{ -- forth line
			{ X =  1, Y = -1, Z = -1 },
			{ X =  1, Y = -1, Z =  0 },
			{ X =  1, Y = -1, Z =  1 }
		}
	},
	{ -- facedir = 2
		{ -- first line
			{ X = -1, Y =  2, Z = -1 },
			{ X =  0, Y =  2, Z = -1 },
			{ X =  1, Y =  2, Z = -1 }
		},
		{ -- second line
			{ X = -1, Y =  1, Z = -1 },
			{ X =  0, Y =  1, Z = -1 },
			{ X =  1, Y =  1, Z = -1 }
		},
		{ -- third line
			{ X = -1, Y =  0, Z = -1 },
			{ X =  0, Y =  0, Z = -1 },
			{ X =  1, Y =  0, Z = -1 }
		},
		{ -- fourth line
			{ X = -1, Y = -1, Z = -1 },
			{ X =  0, Y = -1, Z = -1 },
			{ X =  1, Y = -1, Z = -1 }
		}
	},
	{ -- facedir = 3
		{ -- first line
			{ X = -1, Y =  2, Z = -1 },
			{ X = -1, Y =  2, Z =  0 },
			{ X = -1, Y =  2, Z =  1 }
		},
		{ -- second line
			{ X = -1, Y =  1, Z = -1 },
			{ X = -1, Y =  1, Z =  0 },
			{ X = -1, Y =  1, Z =  1 }
		},
		{ -- third line
			{ X = -1, Y =  0, Z = -1 },
			{ X = -1, Y =  0, Z =  0 },
			{ X = -1, Y =  0, Z =  1 }
		},
		{ -- fourth line
			{ X = -1, Y = -1, Z = -1 },
			{ X = -1, Y = -1, Z =  0 },
			{ X = -1, Y = -1, Z =  1 }
		}
	}
}

tbm.newposline = 3
tbm.newposcolumn = 2
tbm.rowbelownewpos = 4

tbm.placetbm = function(pos, fuel)
	-- will correctly pace a TBM at the position indicated
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec",
		"size[8,9]"..
		"list[current_name;main;0,0;1,4;]"..
		"item_image[1,0;1,1;tbm:coke]"..
		"image[1,1;1,1;default_cobble.png]"..
		"item_image[1,2;1,1;default:torch]"..
		"item_image[1,3;1,1;default:rail]"..
		"list[current_name;inv;2,0;6,4;]"..
		"list[current_player;main;0,5;8,4;]")
	meta:set_string("infotext", "Tunnel Boring Machine")
	meta:set_string("fuel", fuel)
	local inv = meta:get_inventory()
	inv:set_size("main", 1*4)
	inv:set_size("inv", 6*4)
end

tbm.findnewpos = function(pos, facing)
	-- will return the position where the machine will go in the next cycle
	local newpos = {}
	local box = tbm.offsets[facing + 1]
	newpos.x = pos.x + box[tbm.newposline][tbm.newposcolumn].X
	newpos.y = pos.y + box[tbm.newposline][tbm.newposcolumn].Y
	newpos.z = pos.z + box[tbm.newposline][tbm.newposcolumn].Z
	return newpos
end

tbm.findoldpos = function(pos, facing)
	-- will return the position where the machine was before (to drop items)
	local oldpos = {}
	if facing==0 then
		oldpos.x = pos.x
		oldpos.z = pos.z - 1
		oldpos.y = pos.y
	elseif facing==1 then
		oldpos.x = pos.x - 1
		oldpos.z = pos.z
		oldpos.y = pos.y
	elseif facing==2 then
		oldpos.x = pos.x
		oldpos.z = pos.z + 1
		oldpos.y = pos.y
	else
		oldpos.x = pos.x + 1
		oldpos.z = pos.z
		oldpos.y = pos.y
	end;
	return oldpos
end

tbm.dropitem = function(pos, item)
    -- Take item in any format
    --[[
    local obj = minetest.add_entity(pos, "__builtin:item")
    obj:get_luaentity():set_item(stack:to_string())
    return obj
    ]]--
    local stack = ItemStack(item)
    local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
    
    if inv:room_for_item("inv", stack) then
      inv:add_item("inv", stack)
    end
end

tbm.findstack = function(inv, name)
	-- will find name in the inventory inv and return its stack or nil
	local h = 0
	if not inv:is_empty("main") then
		for h = 1, inv:get_size("main") do
			local stack = inv:get_stack("main", h)
			if stack:get_name() == name then
				return stack
			end
		end
	else
		return nil
	end
end

tbm.getstackcount = function(pos, name)
	-- will return the amount of name in all stacks at position pos
	local h = 0
	local inv = minetest.get_meta(pos):get_inventory()
	local found = 0
	if not inv:is_empty("main") then
		for h = 1, inv:get_size("main") do
			local stack = inv:get_stack("main", h)
			if stack:get_name() == name then
				if not stack:is_empty() then
					found = found + stack:get_count()
				end
			end
		end
	end
	return found
end

tbm.setstackcount = function(pos, name, count)
	-- will make n stacks at position pos so that they
	-- together makes up for count items of the item name
	local inv = minetest.get_meta(pos):get_inventory()
	local found = tbm.getstackcount(pos, name) + count
	local numberofstacks = math.floor(found / 99)
	local laststacksize = found % 99
	local h = 0
	for h = 1, numberofstacks do
		inv:add_item("main", name.." 99")
	end
	inv:add_item("main", name.." "..laststacksize)
end

tbm.breakstones = function(pos, facing)
	-- will break all stones in front of the machine
	local block = tbm.offsets[facing + 1]
	local i = 1
	local j = 1
	local bpos = {}
	local oldpos = tbm.findoldpos(pos, facing)
	local cobbleresult = 0
	for i = 1, 3 do
		for j = 1, 3 do
			bpos.x = pos.x + block[i][j].X
			bpos.y = pos.y + block[i][j].Y
			bpos.z = pos.z + block[i][j].Z
			local current = minetest.get_node(bpos)
			if current.name ~= 'air' and current.name ~= 'ignore' then 
				if current.name == "default:mese" then
					tbm.dropitem(pos, "default:mese")
				else
					local dropped = ItemStack({name=current.name}):get_definition().drop
					if dropped ~= "default:cobble" then
						tbm.dropitem(pos, dropped)
					else
						tbm.dropitem(pos, dropped)
						--cobbleresult = cobbleresult + 1
					end
				end
				minetest.dig_node(bpos)
			end
		end
	end
	return cobbleresult
end

tbm.placecobble = function(pos, facing)
	-- place cobblestone below where the machine will be
	local box = tbm.offsets[facing + 1]
	local i = 1
	local ppos = {}
	for i = 1, 3 do
		ppos.x = pos.x + box[tbm.rowbelownewpos][i].X
		ppos.y = pos.y + box[tbm.rowbelownewpos][i].Y
		ppos.z = pos.z + box[tbm.rowbelownewpos][i].Z
		minetest.add_node(ppos, { name = "default:cobble" })
	end
end

tbm.placetorch = function(pos, facing)
	-- places a torch besides the track
	local box = tbm.offsets[facing + 1]
	local ppos = {}
	ppos.x = pos.x + box[tbm.newposline][1].X
	ppos.y = pos.y + box[tbm.newposline][1].Y
	ppos.z = pos.z + box[tbm.newposline][1].Z
	minetest.place_node(ppos, { name = "default:torch" })
end

tbm.placetrack = function(pos, facing)
	-- places a track behind the machine
	local ppos = tbm.findoldpos(pos, facing)
	minetest.place_node(ppos, { name = "default:rail" } )
end

minetest.register_node("tbm:tbm", {
	description = "Tunnel Boring Machine",
         tiles = {"tbm_side.png", 
                           "tbm_side.png", 
                           "tbm_side.png", 
                           "tbm_side.png", 
                           {name="tbm_front_animated.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=0.6}},
                           "tbm_side.png"},
	paramtype = "light",
	inventory_image = "tbm_inv.png",
	wield_image = "tbm_inv.png",
	paramtype2 = 'facedir',
	light_source = 10,
	drawtype = "nodebox",
	node_box = {
	type = "fixed",
	fixed = {
		{-1.500000,-0.500000,-0.500000,1.500000,2.500000,0.500000}, --front
		{-1.500000,-0.500000,-0.500000,-1.300000,2.500000,-4.500000}, --left
		{-1.500000,2.300000,-0.500000,1.500000,2.500000,-4.500000}, --top
		{1.300000,-0.500000,-0.500000,1.500000,2.500000,-4.500000}, --right
		{-1.500000,-0.500000,-0.500000,1.500000,-0.300000,-4.500000}, --bottom
		},
	},
	groups = {cracky=1},
	on_construct = function(pos)
		tbm.placetbm(pos, "0")
		minetest.after(10, function()
			tbm.drill(pos)
		end)
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main") and inv:is_empty("inv")
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "main" then
		  minetest.after(10, function()
			  tbm.drill(pos)
		  end)
	  end
	end,
})

tbm.drill = function(pos)
  local facing = minetest.get_node(pos).param2
	local lightcount = minetest.get_node(pos).param1
	local newpos = tbm.findnewpos(pos, facing)
	local oldpos = tbm.findoldpos(pos, facing)
	local cokecount = tbm.getstackcount(pos, "tbm:coke")
	local cobblecount = tbm.getstackcount(pos, "default:cobble")
	local torchcount = tbm.getstackcount(pos, "default:torch")
	local railcount = tbm.getstackcount(pos, "default:rail")
	-- Current metadata
	local meta = minetest.get_meta(pos)
	-- Current inventory
	local inv = meta:get_inventory()
	local fuel = tonumber(meta:get_string("fuel"))
	if fuel == nil then
		fuel = 0
	end
	-- check fuel, if below 1, grab a coal if coal > 0 else, do nothing
	if fuel == 0 then
		if cokecount > 0 then
			fuel = 3
			cokecount = cokecount - 1
		end
	end
	-- only work if there is fuel, three cobblestones, one track and one torch
	if (fuel > 0) and (cobblecount > 2) and (railcount > 0) and (torchcount > 0) then
		fuel = fuel - 1
		-- break nodes ahead of the machine
		local addcobble = tbm.breakstones(pos, facing)
		-- put cobble to make bridges
		tbm.placecobble(pos, facing)
		cobblecount = cobblecount - 3
		if cobblecount < 99 then
			cobblecount = cobblecount + addcobble
		end
		if fuel == 0 then
			if torchcount > 0 then
				tbm.placetorch(pos, facing)
				torchcount = torchcount - 1
			end
		end
		if railcount > 0 then
			tbm.placetrack(pos, facing)
			railcount = railcount - 1
		end
		-- create new TBM at the new position 
		minetest.add_node(newpos, { name="tbm:tbm", param1=lightcount, param2=facing })
		-- create inventory and other meta data at the new position
		tbm.placetbm(newpos, tostring(fuel))
		-- move tbm stack to the new position
		tbm.setstackcount(newpos, "tbm:coke", cokecount)
		tbm.setstackcount(newpos, "default:cobble", cobblecount)
		tbm.setstackcount(newpos, "default:torch", torchcount)
		tbm.setstackcount(newpos, "default:rail", railcount)
		
		local list = inv:get_list("inv")
		local newmeta = minetest.get_meta(newpos)
		local inv = newmeta:get_inventory()
		inv:set_list("inv", list)
		-- remove tbm from old position
		minetest.remove_node(pos)
	else
		meta:set_string("fuel", "0")
	end
	--play sound
         minetest.sound_play("tbm", {pos = pos, gain = 1.0, max_hear_distance = 10,})
end

minetest.register_node("tbm:metal_plate", {
	drawtype = "signlike",
	description = "Metal Plating",
	tiles = {"tbm_side.png"},
	inventory_image = "tbm_side.png",
	wield_image = "tbm_side.png",
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = false,
	is_ground_content = false,
	selection_box = {
		type = "wallmounted",
	},
	drop = "tbm:metal_plate",
	groups = {cracky=2},
})

minetest.register_craftitem("tbm:engine", {
	description = "TBM Engine",
	inventory_image = "tbm_engine.png",
})

minetest.register_craftitem("tbm:drill", {
	description = "TBM Drill",
	inventory_image = "tbm_front.png",
})

minetest.register_craftitem("tbm:coke", {
	description = "TBM Coal Coke",
	inventory_image = "tbm_coke.png",
})

--Crafting--

minetest.register_craft({
	output = 'tbm:metal_plate 2',
	recipe = {
		{'default:steel_ingot', 'default:steel_ingot'},
		{'default:steel_ingot', 'default:steel_ingot'},
	}
})

minetest.register_craft({
	output = 'tbm:engine',
	recipe = {
		{'tbm:metal_plate', 'tbm:metal_plate', 'tbm:metal_plate'},
		{'tbm:metal_plate', 'default:furnace', 'tbm:metal_plate'},
		{'tbm:metal_plate', 'tbm:metal_plate', 'tbm:metal_plate'},
	}
})

minetest.register_craft({
	output = 'tbm:drill',
	recipe = {
		{'', 'default:diamond', ''},
		{'default:diamond', 'default:stick', 'default:diamond'},
		{'', 'default:diamond', ''},
	}
})

minetest.register_craft({
	output = 'tbm:tbm',
	recipe = {
		{'tbm:metal_plate', 'tbm:drill', 'tbm:metal_plate'},
		{'tbm:metal_plate', 'tbm:engine', 'tbm:metal_plate'},
		{'tbm:metal_plate', 'default:chest', 'tbm:metal_plate'},
	}
})

minetest.register_craft({
	type = "cooking",
	output = "tbm:coke",
	recipe = "default:coal_lump",
})

minetest.register_craft({
	type = "fuel",
	recipe = "tbm:coke",
	burntime = 80,
})

-- Alternate recipes in case the Steel mod is installed.
-- These first two allow to cross-convert between TBM metal plate and
-- Steel mod soft steel plate.

minetest.register_craft({
    output = 'tbm:metal_plate 2',
    recipe = {
        {'steel:plate_soft', 'steel:plate_soft'},
    }
})

minetest.register_craft({
    output = 'steel:plate_soft 2',
    recipe = {
        {'tbm:metal_plate', 'tbm:metal_plate'},
    }
})

-- These two allow crafting TBM components from the Steel mod's soft steel plate

minetest.register_craft({
    output = 'tbm:engine',
    recipe = {
        {'steel:plate_soft', 'steel:plate_soft', 'steel:plate_soft'},
        {'steel:plate_soft', 'default:furnace', 'steel:plate_soft'},
        {'steel:plate_soft', 'steel:plate_soft', 'steel:plate_soft'},
    }
})

minetest.register_craft({
    output = 'tbm:tbm',
    recipe = {
        {'steel:plate_soft', 'tbm:drill', 'steel:plate_soft'},
        {'steel:plate_soft', 'tbm:engine', 'steel:plate_soft'},
        {'steel:plate_soft', 'default:chest', 'steel:plate_soft'},
    }
})