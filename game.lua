local World = require "worldgen"

local overworld = nil

function start()
	overworld = World("assets/moon.png", 1)

end

function update(dt)
	overworld:update(dt)
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
