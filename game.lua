local worldgen = require "worldgen"

local overworld = nil

function start()
	overworld = worldgen.generate("assets/moon.png", 1)
	
end

function update(dt)
end

function pressed(btn)
end

function released(btn)
end

return {
	start = start,
	update = update,
	pressed = pressed,
	released = released,
}