
local UFO_SPEED = 10
local UFO_TURN_SPEED = 2

local ufo = {
	physical = true,
	collisionbox = {-1.5,-.5,-1.5, 1.5,2,1.5},
	visual = "mesh",
	mesh = "ufo.x",
	textures = {"ufo.png"},
	
	driver = nil,
	v = 0
}
function ufo:on_rightclick (clicker)
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

function ufo:on_activate (staticdata, dtime_s)
	self.object:set_armor_groups({immortal=1})
end

function ufo:on_punch (puncher, time_from_last_punch, tool_capabilities, direction)
	self.object:remove()
	if puncher and puncher:is_player() then
		puncher:get_inventory():add_item("main", "ufos:ufo")
	end
end

function ufo:on_step (dtime)
	if self.driver then
		local ctrl = self.driver:get_player_control()
		local vel = self.object:getvelocity()
		local acc = self.object:getacceleration()
		if ctrl.up then
			vel.x = math.cos(self.object:getyaw()+math.pi/2)*UFO_SPEED
			vel.z = math.sin(self.object:getyaw()+math.pi/2)*UFO_SPEED
			acc.x = vel.x*.25
			acc.z = vel.z*.25
		else
			acc.x = -vel.x/5
			acc.z = -vel.z/5
		end
		if ctrl.down then
			acc.x = -vel.x
			acc.z = -vel.z
		end
		if ctrl.jump then
			vel.y = UFO_SPEED
		elseif ctrl.sneak then
			vel.y = -UFO_SPEED
		else
			acc.y = -vel.y/2
		end
		self.object:setvelocity(vel)
		self.object:setacceleration(acc)
		if ctrl.left then
			self.object:setyaw(self.object:getyaw()+math.pi/120*UFO_TURN_SPEED)
		end
		if ctrl.right then
			self.object:setyaw(self.object:getyaw()-math.pi/120*UFO_TURN_SPEED)
		end
	end
end

minetest.register_entity("ufos:ufo", ufo)


minetest.register_craftitem("ufos:ufo", {
	description = "ufo",
	inventory_image = "ufo.png",
	wield_image = "ufo.png",
	
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing.type ~= "node" then
			return
		end
		minetest.env:add_entity(pointed_thing.above, "ufos:ufo")
		itemstack:take_item()
		return itemstack
	end,
})

