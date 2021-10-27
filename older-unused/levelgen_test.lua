local lg = love.graphics

local levelgen = require "levelgen"

local level = nil

local cd = love.image.newImageData(65, 65)
local c = lg.newImage(cd)

local colSet = {1, 1, 1}
local colReset = {0, 0, 0, 0}
local function genImg(dmap)
	for j=1, 32 do
		for i=1, 32 do
			local x = i*2-1
			local y = j*2-1
			if i==1 then
				cd:setPixel(0, y, colSet)
				cd:setPixel(0, y+1, colSet)
			end
			if j==1 then
				cd:setPixel(x, 0, colSet)
				cd:setPixel(x+1, 0, colSet)
			end
			cd:setPixel(x+1, y+1, colSet)
			local c = dmap[j][i]
			if c % 8 >= 4 then
				cd:setPixel(x+1, y, colReset)
			else
				cd:setPixel(x+1, y, colSet)
			end
			if c % 16 >= 8 then
				cd:setPixel(x, y+1, colReset)
			else
				cd:setPixel(x, y+1, colSet)
			end
		end
	end
	c:replacePixels(cd)
end

local stepFn=nil
function start()
	level, stepFn = levelgen.generate("assets/moon.png", 1, true)
	genImg(level)
end

local spritesheet = require "spritesheet"
local spr = spritesheet.build {
	fileName = "assets/moon.png",
}
local speed = 0.25
local cdt = 0
function update(dt)
	lg.push()
	lg.scale(3, 3)
	lg.push()
	lg.scale(2, 2)
	lg.draw(spr.image)
	lg.pop()
	lg.draw(c)
	lg.pop()
	
	if stepFn then
		cdt = cdt + dt
		if cdt >= speed then
			cdt = cdt - speed
			stepFn()
			genImg(level)
		end
	end
end

function pressed(btn)
end

function released(btn)
	if btn == "up" then
		speed = math.max(0.03125, speed / 2)
	end
	if btn == "down" then
		speed = math.min(4, speed * 2)
	end
end

return {
	start = start,
	update = update,
	pressed = pressed,
	released = released,
}