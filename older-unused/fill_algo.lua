local lg = love.graphics
local li = love.image

local util = require "util"
local pprint = util.pprint

local width, height = nil
local image = nil
local iData = nil
local canvas = nil
local cData = nil
local stacks = {}
local first = nil
local gmap = nil
local function createMap(name)
	iData = li.newImageData(name)
	image = lg.newImage(iData)

	first = {iData:getPixel(0, 0)}
	pprint(first)
	local w, h = iData:getDimensions()
	width, height = w, h 
	local map = {}
	for j=1, h do
		map[j] = {}
		for i=1, w do
			map[j][i] = {
				checked = false
			}
		end
	end
	gmap = map

	cData = li.newImageData(width, height)
	canvas = lg.newImage(cData)
end

function step(stack)
	if #stack == 0 then
		return false
	end
	local x, y = unpack(stack[#stack])

	cData:setPixel(x-1, y-1, unpack(first))
	canvas = lg.newImage(cData)
	gmap[y][x].checked = true

	local ds = {}
	local function check(dx, dy)
		local nx, ny = x + dx, y + dy

		if nx < 1 or ny < 1 or nx > width or ny > height then
			return
		end
		local ic = {iData:getPixel(nx-1, ny-1)}
		for i=1, 3 do
			if ic[i] ~= first[i] then
				return
			end
		end
		if gmap[ny][nx].checked then
			return
		end

		ds[#ds + 1] = {dx, dy}
	end

	check(-1, 0)
	check(0, -1)
	check(1, 0)
	check(0, 1)

	local function walkTo(dx, dy)
		local nx = x + dx
		local ny = y + dy
		local ic = {iData:getPixel(nx-1, ny-1)}
		for i=1, 3 do
			if ic[i] ~= first[i] then
				return
			end
		end
		stack[#stack + 1] = {nx, ny}
	end

	if #ds > 0 then
		if #ds == 3 and math.random() < 0.2 then
			for i=1, 3 do	
				stacks[#stacks+1] = {{ds[i][1]+x, ds[i][2]+y}}
			end
		else
			local i = math.random(1, #ds)
			walkTo(ds[i][1], ds[i][2])
		end
	else
		table.remove(stack)
	end

	return true
end

function start()
	createMap("assets/moon.png")

	local x, y = nil
	while not x or not y do
		x, y = math.random(1, width), math.random(1, height)
		local c = {iData:getPixel(x-1, y-1)}
		for i=1, 3 do
			if c[i] ~= first[i] then
				x, y = nil
				break
			end
		end
	end

	gmap[y][x].checked = true
	stacks = {{{x, y}}}
end

local showImg = true
local odt = 0
local cdt = 0
local angle = 0
function update(dt)
	cdt = cdt + dt
	angle = angle + dt*2
	if canvas then
		lg.push()
		lg.scale(4)
		if showImg then
			local a = math.sin(angle) * 0.25 + 0.25
			lg.setColor(a, a, a)
			lg.draw(image, 0, 0)
			lg.setColor(1, 1, 1)
		end
		lg.draw(canvas, 0, 0)

		for _, stack in ipairs(stacks) do
			local x, y = nil
			if #stack > 0 then 
				x, y = unpack(stack[#stack])
				lg.rectangle('fill', x-1, y-1, 1, 1)
			end
		end
		lg.pop()
	end

	if cdt < odt + 0.2 then return end
	odt = cdt

	local nstack = {}
	for _, stack in ipairs(stacks) do
		if step(stack) then
			nstack[#nstack+1] = stack
		end
	end
	stack = nstack
end

function pressed(btn)
	if btn == "left" then
		showImg = true
	elseif btn == "right" then
		showImg = false
	end
end

function released(btn)
end

return {
	start = start,
	update = update,
	pressed = pressed,
	released = released,
}