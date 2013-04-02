
ufos = {}

local UFO_SPEED = 1
local UFO_TURN_SPEED = 2
local UFO_MAX_SPEED = 10
local UFO_FUEL_USE = .01

ufos.fuel_from_wear = function(wear)
	local fuel
	if wear == 0 then
		fuel = 0
	else
		fuel = (65535-(wear-1))*100/65535
	end
	return fuel
end

ufos.wear_from_fuel = function(fuel)
	local wear = (100-(fuel))*65535/100+1
	if wear > 65535 then wear = 0 end
	return wear
end

ufos.get_fuel = function(self)
	--return self.object:get_hp()
	return self.fuel
end

ufos.set_fuel = function(self,fuel,object)
	--[[if not object then object = self.object end
	object:set_hp(fuel)]]
	self.fuel = fuel
end

ufos.ufo_to_item = function(self)
	local wear = ufos.wear_from_fuel(ufos.get_fuel(self))
	return {name="ufos:ufo",wear=wear}
end

ufos.ufo_from_item = function(itemstack,placer,pointed_thing)
	-- restore the fuel inside the item
	local wear = itemstack:get_wear()
	ufos.set_fuel(ufos.ufo,ufos.fuel_from_wear(wear))
	-- add the entity
	e = minetest.env:add_entity(pointed_thing.above, "ufos:ufo")
	-- remove the item
	itemstack:take_item()
end


ufos.ufo = {
	physical = true,
	collisionbox = {-1.5,-.5,-1.5, 1.5,2,1.5},
	visual = "mesh",
	mesh = "ufo.x",
	textures = {"ufo_0.png"},
	
	driver = nil,
	v = 0,
	fuel = 0,
	fueli = 0
}
function ufos.ufo:on_rightclick (clicker)
	if not clicker or not clicker:is_player() then
		return
	end
	if self.driver and clicker == self.driver then
		self.driver = nil
		clicker:set_detach()
	elseif not self.driver then
		self.driver = clicker
		clicker:set_attach(self.object, "", {x=0,y=5,z=0}, {x=0,y=0,z=0})
	end
end

function ufos.ufo:on_activate (staticdata, dtime_s)
	self.object:set_armor_groups({immortal=1})
end

function ufos.ufo:on_punch (puncher, time_from_last_punch, tool_capabilities, direction)
	self.object:remove()
	if puncher and puncher:is_player() then
		-- wear: save the fuel inside the itemstack
		puncher:get_inventory():add_item("main", ufos.ufo_to_item(self))
	end
end

function ufos.ufo:on_step (dtime)
	local fuel = ufos.get_fuel(self)
	if self.driver then
		local ctrl = self.driver:get_player_control()
		local vel = self.object:getvelocity()
		if fuel == nil then fuel = 0 end
		if fuel > 0 and ctrl.up then
			vel.x = vel.x + math.cos(self.object:getyaw()+math.pi/2)*UFO_SPEED
			vel.z = vel.z + math.sin(self.object:getyaw()+math.pi/2)*UFO_SPEED
			fuel = fuel - UFO_FUEL_USE
		else
			vel.x = vel.x*.99
			vel.z = vel.z*.99
		end
		if ctrl.down then
			vel.x = vel.x*.9
			vel.z = vel.z*.9
		end
		if fuel > 0 and ctrl.jump then
			vel.y = vel.y+UFO_SPEED
			fuel = fuel - UFO_FUEL_USE
		elseif fuel > 0 and ctrl.sneak then
			vel.y = vel.y-UFO_SPEED
			fuel = fuel - UFO_FUEL_USE
		else
			vel.y = vel.y*.9
		end
		if vel.x > UFO_MAX_SPEED then vel.x = UFO_MAX_SPEED end
		if vel.x < -UFO_MAX_SPEED then vel.x = -UFO_MAX_SPEED end
		if vel.y > UFO_MAX_SPEED then vel.y = UFO_MAX_SPEED end
		if vel.y < -UFO_MAX_SPEED then vel.y = -UFO_MAX_SPEED end
		if vel.z > UFO_MAX_SPEED then vel.z = UFO_MAX_SPEED end
		if vel.z < -UFO_MAX_SPEED then vel.z = -UFO_MAX_SPEED end
		self.object:setvelocity(vel)
		if ctrl.left then
			self.object:setyaw(self.object:getyaw()+math.pi/120*UFO_TURN_SPEED)
		end
		if ctrl.right then
			self.object:setyaw(self.object:getyaw()-math.pi/120*UFO_TURN_SPEED)
		end
		if ctrl.aux1 then
			local pos = self.object:getpos()
			local t = {{x=2,z=0},{x=-2,z=0},{x=0,z=2},{x=0,z=-2}}
			for _, i in ipairs(t) do
				pos.x = pos.x + i.x; pos.z = pos.z + i.z;
				if minetest.env:get_node(pos).name == "ufos:furnace" then
					meta = minetest.env:get_meta(pos)
					if fuel < 100 and meta:get_int("charge") > 0 then
						fuel = fuel + 1
						meta:set_int("charge",meta:get_int("charge")-1)
						meta:set_string("formspec", ufos.furnace_inactive_formspec
							.. "label[0,0;Charge: "..meta:get_int("charge"))
					end
				end
				pos.x = pos.x - i.x; pos.z = pos.z - i.z;
			end
		end
	end
	
	if fuel < 0 then fuel = 0 end
	if fuel > 100 then fuel = 100 end
	if self.fueli ~= math.floor(fuel*8/100) then
		self.fueli = math.floor(fuel*8/100)
		print(self.fueli)
		self.textures = {"ufo_"..self.fueli..".png"}
		self.object:set_properties(self)
	end
	ufos.set_fuel(self,fuel)
end

minetest.register_entity("ufos:ufo", ufos.ufo)


minetest.register_tool("ufos:ufo", {
	description = "ufo",
	inventory_image = "ufos_inventory.png",
	wield_image = "ufos_inventory.png",
	tool_capabilities = {load=0,max_drop_level=0, groupcaps={fleshy={times={}, uses=100, maxlevel=0}}},
	
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		ufos.ufo_from_item(itemstack,placer,pointed_thing)
		return itemstack
	end,
})

minetest.register_craft( {
	output = 'ufos:ufo',
	recipe = {
		{ "", "default:glass", ""},
		{ "default:mese_crystal_fragment", "", "default:mese_crystal_fragment"},
		{ "default:steelblock", "default:mese", "default:steelblock"},
	},
})

dofile(minetest.get_modpath("ufos").."/furnace.lua")

