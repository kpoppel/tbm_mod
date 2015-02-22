-- a Tunnel Boring Machine

--  Idea to enable digging through lava and water  get a slot for gravel that the TBM can use in front of the machine to clean that and dig it again with some loss or converted to cobble or something. Then I can tunnel through lava pools just fine.

tbm = {}

tbm.placetbm = function(pos, fuel)
   -- will correctly pace a TBM at the position indicated
   local meta = minetest.get_meta(pos)
   meta:set_string("formspec",
                   "size[8,10]"..
                   "background[0,0;8,10;tbm_gui.png]"..
                   "item_image[0,0;1,1;tbm:coke]"..
                   "item_image[1,0;1,1;default:torch]"..
                   "item_image[2,0;1,1;default:rail]"..
                   "item_image[7,0;1,1;default:gravel]"..
                   "list[current_name;main;0,1;8,1;]"..
                   "list[current_name;inv;0,2;8,3;]"..
                   "list[current_player;main;0,6;8,4;]")
   meta:set_string("infotext", "Tunnel Boring Machine")
   meta:set_string("fuel", fuel)
   local inv = meta:get_inventory()
   inv:set_size("main", 8*1)
   inv:set_size("inv", 8*3)
end

tbm.addfacedirpos = function(pos, addpos, facedir)
   -- assuming pos is in X-direction (facedir=1) transpose this to the actual facedir
   local transpos = {}
   if     facedir == 0 then -- +Z
      transpos = { x = -addpos.z, y = addpos.y, z = addpos.x }
   elseif facedir == 1 then -- +X
      transpos = addpos
   elseif facedir == 2 then -- -Z
      transpos = { x = addpos.z, y = addpos.y, z = -addpos.x }
   else                     -- -X
      transpos = { x = -addpos.x, y = addpos.y, z = -addpos.z }
   end
   transpos = { x = transpos.x + pos.x,
		y = transpos.y + pos.y,
		z = transpos.z + pos.z }
   return transpos
end

tbm.dropitem = function(pos, item)
   -- Take item in any format
   local stack = ItemStack(item)
   local meta  = minetest.get_meta(pos)
   local inv   = meta:get_inventory()

   if inv:room_for_item("inv", stack) then
      inv:add_item("inv", stack)
   end
end

tbm.getstack_at = function(pos, stackpos)
   -- uses inventory 'main'
   -- will return the amount and name at stackpos at position pos
   local inv   = minetest.get_meta(pos):get_inventory()
   local count = 0
   local name  = ""
   -- find right material at right position
   if not inv:is_empty("main") then
      local stack = inv:get_stack("main", stackpos)
      if not stack:is_empty() then
	 count = stack:get_count()
	 name  = stack:get_name()
      end
   end
   return name, count
end

tbm.setstackcount = function(pos, stackpos, name, count)
   -- uses inventory 'main'
   -- sets the stackpos to contain count of name
   local inv   = minetest.get_meta(pos):get_inventory()
   -- set right material at right position
   local stack = ItemStack({name=name, count=count})
   inv:set_stack("main", stackpos, stack)
end

tbm.resupply = function(pos, material, count)
   -- find material in mining inventory and resupply the machine
   local inv   = minetest.get_meta(pos):get_inventory()
--   minetest.debug("Incoming:"..material..":"..count)

   if count < 99 and not inv:is_empty("main") and not inv:is_empty("inv") then
      -- How much to take
      local fillstack = ItemStack( {name=material, count=99-count, wear=0, metadata=""} )
--      minetest.debug("Fillstack:"..dump(fillstack:get_count()))
      -- how much I got
      local gotstack  = inv:remove_item("inv", fillstack)
--      minetest.debug("Gotstack:"..dump(gotstack:get_count()))
      count = count + gotstack:get_count()
   end
--   minetest.debug("Outgoing:"..material..":"..count)
   return count
end

tbm.breakstones = function(pos, facedir, floorcount, ceilcount, leftcount, rightcount, gravelcount)
   -- will break all nodes in front of the machine
   -- if gravel is present it will be injected in front of the machine to remove an water or lava
   local y = -1
   local z = -1

   -- Lava and water is handled such that we look two nodes ahead.
   -- if lava or water is detected we replace it with cobblestone in case of lava and sand in case of water
   -- and subtract the same abount of gravel.
   for y = 0, 2 do -- digs both above and below the boring head in order to place floor and possibly ceiling
      for z = -1, 1 do
	 if gravelcount > 0 then
	    local bpos    = tbm.addfacedirpos(pos, { x = 2, y = y, z = z }, facedir)
	    local current = minetest.get_node(bpos)
	    if current.name == 'default:lava_source' then -- or current.name == 'default:lava_flowing' then 
	       minetest.add_node(bpos, { name = "default:cobble" })
	       gravelcount = gravelcount - 1
	    elseif current.name == 'default:water_source' then -- or current.name == 'default:water_flowing' then
	       minetest.add_node(bpos, { name = "default:dirt" })
	       gravelcount = gravelcount - 1
	    end
	 end
      end
   end

   -- Depending on the content of ceiling, left and right side material
   -- the TBM must dig differently
   local ymax = 2
   local zmin = -1
   local zmax =  1
   if ceilcount  > 2 then ymax =  3 end
   if leftcount  > 2 then zmin = -2 end
   if rightcount > 2 then zmax =  2 end

   for y = -1, ymax do -- digs both above and below the boring head in order to place floor and possibly ceiling
      for z = zmin, zmax do
	 -- Don't dig the corners
	 if (y == -1 or y == 3) and (z == -2 or z == 2) then
	    -- nothing
	 else
	   local bpos    = tbm.addfacedirpos(pos, {x = 1, y = y, z = z }, facedir)
	   local current = minetest.get_node(bpos)
	   if current.name ~= 'air' and current.name ~= 'ignore' then
	      -- If there is no "drop" field on definition table, take the name of the block
	      if ItemStack({name=current.name}):get_definition().drop == nil then
		 local dropped = ItemStack({name=current.name}):get_name()
		 tbm.dropitem(pos, dropped)
	      else
		 local dropped = ItemStack({name=current.name}):get_definition().drop
		 tbm.dropitem(pos, dropped)
	      end
--	      if dropped ~= "default:cobble" then
--		 tbm.dropitem(pos, dropped)
--	      else
		 tbm.dropitem(pos, dropped)
--	      end
	      minetest.dig_node(bpos)
	    end
         end
      end
   end
   return gravelcount
end

tbm.placetunnel = function(pos, facedir, where, material)
   -- pos = position of node
   -- facedir = direction
   -- where:
   --  0 = floor
   --  1 = ceiling
   --  2 = left
   --  3 = right
   -- material what to place.
   local ppos  = {}
   local i     = 0

   for i = -1, 1 do
      if     where == 0 then -- floor
	 ppos = tbm.addfacedirpos(pos, {x = 1, y =   -1, z =  i }, facedir)
      elseif where == 1 then -- ceiling
	 ppos = tbm.addfacedirpos(pos, {x = 1, y =    3, z =  i }, facedir)
      elseif where == 2 then -- left
	 ppos = tbm.addfacedirpos(pos, {x = 1, y =  i+1, z =  2 }, facedir)
      elseif where == 3 then -- right
	 ppos = tbm.addfacedirpos(pos, {x = 1, y =  i+1, z = -2 }, facedir)
      end
      minetest.add_node(ppos, { name = material })
   end
end

tbm.placetorch = function(pos, facedir, material)
   -- places a torch besides the track. I cannot get it to attach to the ceiling.
   local ppos = tbm.addfacedirpos(pos , {x = -1, y = 0, z = 1 }, facedir)
   minetest.place_node(ppos, { name = material })
end

tbm.placetrack = function(pos, facedir, material)
   -- places a track behind the machine
--   local ppos = tbm.findoldpos(pos, facedir)
   local ppos = tbm.addfacedirpos(pos, { x = -1, y = 0, z = 0 }, facedir)

   minetest.place_node(ppos, { name = material } )
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
                          minetest.after(6, function()
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
                             minetest.after(6, function()
                                               tbm.drill(pos)
                                               end)
                          end
                       end,
                   })

tbm.drill = function(pos)
   local facedir    = minetest.get_node(pos).param2
   local lightcount = minetest.get_node(pos).param1
   local newpos     = tbm.addfacedirpos(pos, { x = 1, y = 0, z = 0 }, facedir)

   local cokename  , cokecount   = tbm.getstack_at(pos, 1)
   local torchname , torchcount  = tbm.getstack_at(pos, 2)
   local railname  , railcount   = tbm.getstack_at(pos, 3)
   local floorname , floorcount  = tbm.getstack_at(pos, 4)
   local ceilname  , ceilcount   = tbm.getstack_at(pos, 5)
   local leftname  , leftcount   = tbm.getstack_at(pos, 6)
   local rightname , rightcount  = tbm.getstack_at(pos, 7)
   local gravelname, gravelcount = tbm.getstack_at(pos, 8)

   -- Current metadata
   local meta = minetest.get_meta(pos)
   -- Current inventory
   local inv = meta:get_inventory()

--   minetest.debug("ceiling:"..ceilname.." : "..ceilcount)
--   minetest.debug(torchcount)
--   minetest.debug(railcount)
--   minetest.debug(cobblecount)

   local fuel = tonumber(meta:get_string("fuel"))
   if fuel == nil then
      fuel = 0
   end

   -- check fuel, if below 1, grab a coal coke if coal coke > 0 else, do nothing
   if fuel == 0 and cokename == "tbm:coke" then
      if cokecount > 0 then
         fuel = 3
         cokecount = cokecount - 1
      end
   end

   -- only work if there is fuel, three floor materials, and one torch
   -- also torch must be the right kind
   if (fuel > 0) and (floorcount > 2) and (torchcount > 0) and (torchname == "default:torch") then
      fuel = fuel - 1

      -- break nodes ahead of the machine - returns the number of gravel left if any.
      gravelcount = tbm.breakstones(pos, facedir, floorcount, ceilcount, leftcount, rightcount, gravelcount)

      -- place floor material
      tbm.placetunnel(pos, facedir, 0, floorname)
      floorcount = floorcount - 3

      -- place rail if available
      if railcount > 0 then
         tbm.placetrack(pos, facedir, railname)
         railcount = railcount - 1
      end

      -- place ceiling material if available
      if ceilcount > 2 then
	 tbm.placetunnel(pos, facedir, 1, ceilname)
	 ceilcount = ceilcount - 3
      end

      -- place left side material if available
      if leftcount > 2 then
	 tbm.placetunnel(pos, facedir, 2, leftname)
	 leftcount = leftcount - 3
      end

      -- place right side material if available
      if rightcount > 2 then
	 tbm.placetunnel(pos, facedir, 3, rightname)
	 rightcount = rightcount - 3
      end

      -- place torch for every fuel burned (3 blocks)
      if fuel == 0 then
	 tbm.placetorch(pos, facedir, torchname)
	 torchcount = torchcount - 1
      end

      -- Re-supply from mined inventory
      cokecount   = tbm.resupply(pos, cokename, cokecount)
      torchcount  = tbm.resupply(pos, torchname, torchcount)
      railcount   = tbm.resupply(pos, railname, railcount)
      floorcount  = tbm.resupply(pos, floorname, floorcount)
      ceilcount   = tbm.resupply(pos, ceilname, ceilcount)
      leftcount   = tbm.resupply(pos, leftname, leftcount)
      rightcount  = tbm.resupply(pos, rightname, rightcount)
      gravelcount = tbm.resupply(pos, gravelname, gravelcount)

      -- create new TBM at the new position
      minetest.add_node(newpos, { name="tbm:tbm", param1=lightcount, param2=facedir })
      -- create inventory and other meta data at the new position
      tbm.placetbm(newpos, tostring(fuel))
      -- move tbm stack to the new position
      tbm.setstackcount(newpos, 1, cokename, cokecount)
      tbm.setstackcount(newpos, 2, torchname, torchcount)
      tbm.setstackcount(newpos, 3, railname, railcount)
      tbm.setstackcount(newpos, 4, floorname, floorcount)
      tbm.setstackcount(newpos, 5, ceilname, ceilcount)
      tbm.setstackcount(newpos, 6, leftname, leftcount)
      tbm.setstackcount(newpos, 7, rightname, rightcount)
      tbm.setstackcount(newpos, 8, gravelname, gravelcount)

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
   minetest.sound_play("tbm", {pos = pos, gain = 5.0, max_hear_distance = 10,})
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
                           type = "cooking",
                           output = "tbm:coke",
                           recipe = "technic:coal_dust",
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


minetest.register_tool("tbm:pick_carbon", {
                          description = "Carbon-Diamond Pickaxe",
                          inventory_image = "tbm_carbon_pick.png",
                          tool_capabilities = {
                             full_punch_interval = 0.00005,
                             max_drop_level=3,
                             groupcaps={
                                cracky = {times={[1]=0.00005, [2]=0.00005, [3]=0.00005}, uses=60, maxlevel=3},
                                crumbly = {times={[1]=0.00005, [2]=0.00005, [3]=0.00005}, uses=60, maxlevel=3},
                                choppy = {times={[1]=0.00005, [2]=0.00005, [3]=0.00005}, uses=60, maxlevel=3},
                                snappy = {times={[1]=0.00005, [2]=0.00005, [3]=0.00005}, uses=60, maxlevel=3},
                             },
                             damage_groups = {fleshy=12},
                          },
                                          })

minetest.register_craft({
                           output = 'tbm:pick_carbon',
                           recipe = {
                              {'default:coal_lump', 'default:diamond', 'default:coal_lump'},
                              {'', 'default:stick', ''},
                              {'', 'default:stick', ''},
                           }
                        })
