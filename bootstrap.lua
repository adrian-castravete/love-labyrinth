local cpath = ...
local croot = cpath:gsub("%.[^%.]+$", "")
if cpath == croot then
	croot = ""
end

local lg = love.graphics

local function bootstrap(gameModule, viewportConfiguration, inputConfiguration)
	local whiteColor = love.getVersion() > 10 and {1, 1, 1} or {255, 255, 255}

	-- Save ("freeze") loaded modules
	local modules = {}
	for key, value in pairs(package.loaded) do
		modules[key] = value
	end

	local inputHooks = {
		"keypressed",
		"joystickpressed",
		"joystickreleased",
		"joystickaxis",
		"touchpressed",
		"touchreleased",
		"touchmoved",
	}

	local function reload()
		-- Restore modules
		for key, value in pairs(package.loaded) do
			if not modules[key] then
				package.loaded[key] = nil
			end
		end

		local function protect(func, level)
			return xpcall(func, function (msg)
				-- Show the error message but let the user press F10 to reload
				local tb = debug.traceback("Error: " .. tostring(msg), level or 1)
				--tb = tb:gsub("%[C%]: in function 'require'%s+age/bootstrap%.lua.*", "")
				tb = tb:gsub("\n+[^\n]+bootstrap%.lua.*", "")
				print(tb)
				love.draw = function ()
					local w, h = lg.getDimensions()
					lg.printf(tb, 0, 12, w)
				end
				love.touchpressed = function ()
					reload()
				end
			end)
		end

		math.randomseed(os.time())
		math.random()
		math.random()
		math.random()

		local viewport = require(croot .. ".viewport")
		viewport.setup(viewportConfiguration)

		local input = require(croot .. ".input")
		function love.keyreleased(key)
			if key == "f10" then
				reload()
				print(os.date("Reloaded at %Y-%m-%d %H:%M:%S"))
			end
			if key == "f12" then
				love.event.quit()
			end
			input.keyreleased(key)
		end

		for _, hook in ipairs(inputHooks) do
			love[hook] = input[hook]
		end

		--[[
		local mouseDown = false
		love.mousepressed = function (...)
		input.touchpressed('x', ...)
		mouseDown = true
		end
		love.mousereleased = function (...)
		mouseDown = false
		input.touchreleased('x', ...)
		end
		love.mousemoved = function (...)
		if mouseDown then
		input.touchmoved('x', ...)
		end
		end
		--]]

		input.setup(inputConfiguration)

		function love.resize(w, h)
			viewport.resize(w, h)
			input.resize(w, h)
		end

		function love.draw()
			viewport.draw()
			input.draw()
		end

		-- Should we fail to require the game,
		local ok = protect(function ()
			local game = require(gameModule)
			game.start()
			function love.update(dt)
				lg.setCanvas(viewport.canvas)
				lg.setColor(whiteColor)
				lg.clear(0, 0, 0)
				local ok = protect(function ()
					game.update(dt)
				end, 3)
				if not ok then
					love.update = nil
				end
				lg.setCanvas()
			end
			input.onButtonPressed(game.pressed)
			input.onButtonReleased(game.released)
		end, 3)
		if not ok then
			love.update = nil
		end
	end

	reload()
end

return bootstrap
