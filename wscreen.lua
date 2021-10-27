local class = require "class"
local tiny = require "tiny"

local objects = require "objects"

local Screen = class()

-- Public {{{
function Screen:init(x, y, free, level)
	self.x = x
	self.y = y
	self.free = free
	self.level = level
	self:reset()
end

function Screen:reset()
	local w = tiny.world()



	self.tinyWorld = w
end

function Screen:update(dt)
	self.tinyWorld:update(dt)
end
-- }}}

-- Private {{{
-- }}}

local function generate(world, x, y)
	local sx, sy = unpack(world.startPos)
	local dcell = world.dirMap[y][x]
	local free = {
		left = bit.band(dcell, 1) > 0,
		up = bit.band(dcell, 2) > 0,
		right = bit.band(dcell, 4) > 0,
		down = bit.band(dcell, 8) > 0,
	}
	local scr = Screen(x, y, free, world.pixelMap[y][x])

	return scr
end

return {
	generate = generate,
}
-- vim: set fdm=marker:
