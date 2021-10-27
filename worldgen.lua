local spritesheet = require "spritesheet"
local util = require "util"
local pprint = util.pprint
local pmap2 = util.pmap2

local function analyse(idata)
	local firstPixel = {idata:getPixel(0, 0)}
	local palette = {firstPixel}
	local gmap = {}
	local pmap = {}
	local pcnt = {}

	-- extract palette
	idata:mapPixel(function (x, y, ...)
		local color = {...}

		local found = false	
		local index = 0
		for j=1, #palette do
			local pcol = palette[j]

			local diff = false
			for i=1, 4 do
				if math.floor(color[i] * 255) ~= math.floor(pcol[i] * 255) then
					diff = true
					break
				end
			end

			if not diff then
				found = true
				index = j
				break
			end
		end 

		if not found then
			index = #palette+1
			palette[index] = color
		end

		return ...
	end)

	for j=1, #palette-1 do
		for i=j+1, #palette do
			local a = 0
			local b = 0
			for k=1, 4 do
				a = a + palette[j][k]
				b = b + palette[i][k]
			end
			if a > b then
				palette[j], palette[i] = palette[i], palette[j]
			end
		end
	end

	idata:mapPixel(function (x, y, ...)
		local color = {...}

		local index = 0
		for j, palCol in ipairs(palette) do
			local found = true
			for i=1, 4 do
				if palCol[i] ~= color[i] then
					found = false
					break
				end
			end
			if found then
				index = j
				break
			end
		end

		if not pmap[y+1] then
			pmap[y+1] = {}
		end
		pmap[y+1][x+1] = index
		
		pcnt[index] = (pcnt[index] or 0) + 1

		return ...
	end)

	--local chMap = " ❖░▒▓█"
	--pmap2(pmap, nil, function (c)
	--	return chMap:sub(c, c)
	--end)

	-- find a starting point with the first color	
	local w, h = idata:getDimensions()
	local sx, sy = nil
	while not sx do
		sx, sy = math.random(1, w), math.random(1, h)
		if pmap[sy][sx] ~= 1 then
			sx = nil
		end
	end

	return {
		palette = palette,
		palCounts = pcnt,
		pixelMap = pmap,
		startPos = {sx, sy},
		width = w,
		height = h,
	}
end

local function walk(info, doStep)
	local stacks = {{info.startPos}}

	local dmap = {}
	for j=1, info.height do
		dmap[j] = {}
		for i=1, info.width do
			dmap[j][i] = 0
		end
	end
	local cIndex = 1
	local border = {}
	
	local function walkStep(stack)
		local x, y = unpack(stack[#stack])
		local dirs = {}
	
		local function testDir(dx, dy, d, o)
			local nx, ny = x + dx, y + dy
	
			if nx < 1 or ny < 1 or nx > info.width or ny > info.height then
				return 
			end
			if dmap[ny][nx] == 0 then
				if info.pixelMap[ny][nx] == cIndex then
					table.insert(dirs, {dx, dy, d, o})
				else
					table.insert(border, {x, y, dx, dy, d, o})
				end
			end
		end
		testDir(-1, 0, 1, 4)
		testDir(0, -1, 2, 8)
		testDir(1, 0, 4, 1)
		testDir(0, 1, 8, 2)
	
		if #dirs < 1 then
			table.remove(stack)
			return
		end

		local function addWalk(cdir, stack)
			local dx, dy, dir, odir = unpack(cdir)
			local nx, ny = x + dx, y + dy
			dmap[y][x] = dmap[y][x] + dir
			dmap[ny][nx] = odir
			table.insert(stack, {nx, ny})
		end
		
		if #dirs >= 3 and math.random() < 0.2 then
			for _, dir in ipairs(dirs) do
				local nstack = {}
				addWalk(dir, nstack)
				table.insert(stacks, nstack)
			end
		else
			addWalk(dirs[math.random(1, #dirs)], stack)
		end
	end
	
	local function step()
		if #stacks < 1 then
			if #border == 0 then
				return false
			end

			local chosen = math.random(1, #border)
			local x, y, dx, dy, dir, odir = unpack(table.remove(border, chosen))
			local nx, ny = x + dx, y + dy
			if dmap[ny][nx] > 0 then
				return true
			end
			stacks = {{{nx, ny}}}
			dmap[y][x] = dmap[y][x] + dir
			dmap[ny][nx] = odir
			cIndex = info.pixelMap[y][x]
		end
		for _, stack in ipairs(stacks) do
			walkStep(stack)
		end
		local nstacks = {}
		for _, stack in ipairs(stacks) do
			if #stack > 0 then
				table.insert(nstacks, stack)
			end
		end
		stacks = nstacks
		return true
	end
	
	if doStep then
		return dmap, step
	end

	while step() do end
	
	return dmap
end

local function generateMaps(fileName, randomSeed, doStep)
	if randomSeed then
		math.randomseed(randomSeed)
	else
		math.randomseed(os.time())
		math.random()
		math.random()
		math.random()
	end

	local sprs = spritesheet.build {
		fileName = fileName,
	}
	local info = analyse(sprs.imageData)
	info.dirMap = walk(info, doStep)
	
	return info
end

local function generate(fileName, randSeed)
	local info = generateMaps(fileName, randSeed)

	function info:showScreen(x, y)
	end
end

return {
	generate = generate,
}