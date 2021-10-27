--- Unified input helper module.
-- WORK-IN-PROGRESS, NEEDS-BETTER-DOCUMENTATION<br/>
-- This module is specific to LÖVE2D.<br/>
-- Used to unify any input methods I may have into one place so keyboard keys
-- and gamepad buttons are treated equally.
local lg = love.graphics
local newLove = love.getVersion() > 10

local input = {}

local listeners = {}
local keyboard = {}
local joyConfig = {}
local joysticks = {}
local touchUI = {}
local showTouchUI = false
local touches = {}
local screenWidth, screenHeight = love.window.getMode()
local normalColour = newLove and {0.75, 0.75, 0.75, 0.25} or {192, 192, 192, 64}
local pressedColour = newLove and {0.25, 0.25, 0.25, 0.25} or {64, 64, 64, 64}
local whiteColour = newLove and {1, 1, 1} or {255, 255, 255}

local function recalculateValues(cfg)
	local hunit = screenHeight / 100
	local hsize = hunit * cfg.size / 2
	local gapX = hunit * cfg.gapX
	local gapY = hunit * cfg.gapY
	local a = cfg.anchor

	local x, y = 0, 0
	if a:find("l") then x = gapX + hsize end
	if a:find("u") then y = gapY + hsize end
	if a:find("r") then x = screenWidth - gapX - hsize end
	if a:find("d") then y = screenHeight - gapY - hsize end

	local vs = {
		x = x,
		y = y,
		r = hsize,
	}

	cfg._values = vs

	return vs
end

local function dispatch(eventType, button)
	if not button then
		return
	end
	for _, listener in ipairs(listeners[eventType] or {}) do
		listener(button)
	end
end

local defaultButtonDrawFn = nil
local function createUIButton(cfg)
	if not cfg.draw then
		cfg.draw = function(r)
			if cfg.pressed then
				lg.setColor(pressedColour)
			else
				lg.setColor(normalColour)
			end
			lg.circle("fill", 0, 0, r)
		end
		defaultButtonDrawFn = cfg.draw
	end

	cfg.tdraw = function()
		local vs = cfg._values or recalculateValues(cfg)
		lg.push()
		lg.translate(vs.x, vs.y)
		cfg.draw(vs.r)
		lg.pop()
	end

	cfg.hit = function(x, y)
		local vs = cfg._values or recalculateValues(cfg)
		local dx, dy = x - vs.x, y - vs.y
		if math.sqrt(dx * dx + dy * dy) < vs.r then
			return true
		end
		return false
	end

	cfg.press = function(x, y)
		dispatch("pressed", cfg.name)
		cfg.pressed = true
	end

	cfg.release = function(x, y)
		dispatch("released", cfg.name)
		cfg.pressed = false
	end

	return cfg
end

local function createUIDPad(cfg)
	local cfg = createUIButton(cfg)
	local dirs = {"left", "up", "right", "down"}
	local pb = {}
	local opb = {}
	for _, n in ipairs(dirs) do
		pb[n] = false
		opb[n] = false
	end
	cfg.pressedDirs = pb
	if not cfg.names then
		cfg.names = {}
	end

	if cfg.draw == defaultButtonDrawFn then
		cfg.draw = function(r)
			local a = math.floor(((cfg.angle or 0) / math.pi + 1) * 4 + 0.5) / 4 * math.pi
			lg.setColor(normalColour)
			if cfg.pressed then
				lg.arc("fill", 0, 0, r, a + 0.7, a + 5.6)
				lg.setColor(pressedColour)
				lg.arc("fill", 0, 0, r, a - 0.7, a + 0.7)
			else
				lg.circle("fill", 0, 0, r)
			end
			lg.setColor(whiteColour)
		end
	end

	local adirs = {
		"right",
		"right down",
		"right down",
		"down",
		"down",
		"down left",
		"down left",
		"left",
		"left",
		"left up",
		"left up",
		"up",
		"up",
		"up right",
		"up right",
		"right",
	}
	local function dpadDispatch(x, y)
		local vs = cfg._values or recalculateValues(cfg)
		local dx, dy = vs.x - x, vs.y - y
		local a = math.atan2(dy, dx)
		cfg.angle = a

		pb, opb = opb, pb
		for _, n in ipairs(dirs) do
			pb[n] = false
		end

		local dzone = nil
		local p = false
		if cfg.deadZone then
			dzone = vs.r * cfg.deadZone
			dzone = dzone * dzone
		end
		if not dzone or dx*dx + dy*dy >= dzone then
			local v = math.floor((1 + a / math.pi) * 8) % 16 + 1
			adirs[v]:gsub("[a-z]+", function(s)
				p = true
				pb[s] = true
			end)
		end

		for _, n in ipairs(dirs) do
			if pb[n] and not opb[n] then
				dispatch("pressed", cfg.names[n] or n)
			elseif opb[n] and not pb[n] then
				dispatch("released", cfg.names[n] or n)
			end
		end
		cfg.pressed = p
	end

	cfg.press = dpadDispatch
	cfg.tmove = dpadDispatch

	cfg.release = function(x, y)
		for _, n in ipairs(dirs) do
			if pb[n] then
				dispatch("released", cfg.names[n] or n)
				pb[n] = false
			end
		end
		cfg.pressed = false
	end

	return cfg
end

local uiCreators = {
	button = createUIButton,
	dpad = createUIDPad,
}

--- Setup function for the input module.
-- @param config Configuration for the input module.
function input.setup(config)
	local kbd = {}
	for name, keys in pairs(config.keyboard or {}) do
		for _, key in ipairs(keys) do
			kbd[key] = name
		end
	end
	keyboard = kbd

	local jcfg = config.joystick or {}
	if not jcfg.axis then
		jcfg.axis = {}
	end
	if not jcfg.buttons then
		jcfg.buttons = {}
	end
	joyConfig = jcfg

	if not config.touch then
		config.touch = {
			controls = {},
		}
	end

	local tCfg = config.touch
	local tui = {}
	for _, cfg in ipairs(tCfg.controls or {}) do
		if not cfg.size then
			cfg.size = 10
		end
		if not cfg.anchor then
			cfg.anchor = "lu"
		end
		if not cfg.gapY then
			cfg.gapY = cfg.gap or 0
		end
		if not cfg.gapX then
			cfg.gapX = cfg.gapY
		end
		tui[#tui+1] = uiCreators[cfg.kind or "button"](cfg)
	end
	touchUI = tui
end

--- Draw function for the input module.
-- Draws any on screen controls.
function input.draw()
	if not showTouchUI then
		return
	end
	lg.push()
	for _, item in ipairs(touchUI) do
		item.tdraw()
	end
	lg.pop()
end

local function resize()
	screenWidth, screenHeight = love.window.getMode()
	for _, c in ipairs(touchUI) do
		c._values = nil
	end
end

--- Resize function.
function input.resize(width, height)
	resize()
end

--- Key pressed callback.
-- Can be assigned to <code>love.keypressed</code>
-- @param key The pressed key.
function input.keypressed(key)
	showTouchUI = false
	if keyboard[key] then
		dispatch("pressed", keyboard[key])
	end
end

--- Key released callback.
-- Can be assigned to <code>love.keyreleased</code>
-- @param key The released key.
function input.keyreleased(key)
	if keyboard[key] then
		dispatch("released", keyboard[key])
	end
end

--- Touch pressed callback.
-- Can be assigned to <code>love.touchpressed</code>
-- @param id The unique identifier of the touch.
-- @param x X position of the touch.
-- @param y Y position of the touch.
function input.touchpressed(id, x, y)
	if not showTouchUI then
		showTouchUI = true
		resize()
	end

	local f = nil
	for _, c in ipairs(touchUI) do
		if c.hit(x, y) then
			if c.press then
				c.press(x, y)
			end
			f = c
			break
		end
	end

	touches[id] = {
		sx = x,
		sy = y,
		x = x,
		y = y,
		c = f,
	}
end

--- Touch released callback.
-- Can be assigned to <code>love.touchreleased</code>
-- @param id The unique identifier of the touch.
-- @param x X position of the touch.
-- @param y Y position of the touch.
function input.touchreleased(id, x, y)
	local t = touches[id]
	t.x = x
	t.y = y

	local c = t.c
	if c and c.release then
		c.release(x, y)
	end
	touches[id] = nil
end

--- Touch moved callback.
-- Can be assigned to <code>love.touchmoved</code>
-- @param id The unique identifier of the touch.
-- @param x X position of the touch.
-- @param y Y position of the touch.
-- @param dx Relative amount of X movement.
-- @param dy Relative amount of Y movement.
function input.touchmoved(id, x, y, dx, dy)
	local t = touches[id]
	t.x = x
	t.y = y

	local c = t.c
	if c then
		if c.tmove then
			c.tmove(x, y)
		end

		local st = c.secondaryTouch
		if st then
			if st.hit(x, y) then
				if st.tmove then
					st.tmove(x, y)
				end
			else
				if st.release then
					st.release()
				end
				c.secondaryTouch = nil
			end
		end

		if not c.secondaryTouch then
			for _, o in ipairs(touchUI) do
				if o.hit(x, y) and o ~= c then
					c.secondaryTouch = o
					if o.press then
						o.press(x, y)
					end
					break
				end
			end
		end
	end
end

local function getJoystick(joy)
	local joyStatus = joysticks[joy]

	if not joyStatus then
		joyStatus = {
			buttons = {},
			axis = {},
		}
		joysticks[joy] = joyStatus
	end

	return joyStatus
end

function input.joystickpressed(joy, btn)
	local joy = getJoystick(joy)
	local act = joyConfig.buttons[btn]
	if act then
		if not joy.buttons[btn] then
			showTouchUI = false
			dispatch("pressed", act)
		end
		joy.buttons[btn] = true
	end
end

function input.joystickreleased(joy, btn)
	local joy = getJoystick(joy)
	local act = joyConfig.buttons[btn]
	if act then
		if joy.buttons[btn] then
			dispatch("released", act)
		end
		joy.buttons[btn] = false
	end
end

function input.joystickaxis(joy, axis, value)
	local joy = getJoystick(joy)

	local axisConfig = joyConfig.axis[axis]
	if axisConfig then
		local threshold = axisConfig.threshold or 0.5
		local names = axisConfig.names
		local ovalue = joy.axis[axis] or 0

		if value >= -threshold and value <= threshold and
			ovalue < -threshold then
			dispatch("released", names[1])
		elseif value >= -threshold and value <= threshold and
			ovalue > threshold then
			dispatch("released", names[2])
		elseif ovalue >= -threshold and ovalue <= threshold and
			value < -threshold then
			dispatch("pressed", names[1])
		elseif ovalue >= -threshold and ovalue <= threshold and
			value > threshold then
			dispatch("pressed", names[2])
		end

		joy.axis[axis] = value
	end
end

--- Register a pressed button listener.
-- @param func Callback function.
function input.onButtonPressed(func)
	local lis = listeners["pressed"]
	if not lis then
		lis = {}
		listeners["pressed"] = lis
	end
	lis[#lis+1] = func
end

--- Register a released button listener.
-- @param func Callback function.
function input.onButtonReleased(func)
	local lis = listeners["released"]
	if not lis then
		lis = {}
		listeners["released"] = lis
	end
	lis[#lis+1] = func
end

return input
