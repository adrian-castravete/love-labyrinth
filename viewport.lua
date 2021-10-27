--- Viewport helper module.
-- This module is specific to LÖVE2D.<br/>
-- Creates an internal canvas that can then be used to draw on the main output
-- canvas.  This helps ensuring a viewport is fitted perfectly to the output
-- screen.<br/>
-- Returns a table containing (and updating) the offset (<code>offsetX</code>,
-- <code>offsetY</code>) and <code>scale</code>.<br/>
-- The table also contains <code>canvas</code>, the canvas to draw to.
-- @author Adrian Castravete
local lg = love.graphics
lg.setDefaultFilter("nearest", "nearest")

local internalWidth = 320
local internalHeight = 240
local pixelScaleX = 1
local pixelScaleY = 1
local fitScreen = false

local outputWidth = 960
local outputHeight = 720
local internalCanvas = nil

local viewport = {
	offsetX = 0,
	offsetY = 0,
	scale = 2,
}

--- Setup function for the viewport module.
-- Before anything can be done with the viewport module this function needs
-- to be called.
--
-- @param config The options you want to set.  When missing, use defaults.
--
-- The default options for <code>config</code>:
-- <ul>
--   <li>width: 320</li>
--   <li>height: 240</li>
--   <li>fitScreen: false</li>
-- </ul>
--
-- Usually, the module tries to respect integer scaling but when
-- <code>fitScreen</code> is truthy, the module will try to fit the internal
-- screen into the output one.
function viewport.setup(config)
	local config = config or {}

	internalWidth = config.width or internalWidth
	internalHeight = config.height or internalHeight
	pixelScaleX = config.pixelScaleX or 1
	pixelScaleY = config.pixelScaleY or 1
	fitScreen = config.fitScreen or false

	viewport.resize(lg.getDimensions())

	if fitScreen then
		lg.setDefaultFilter("linear", "linear", 4)
	end
	internalCanvas = lg.newCanvas(internalWidth, internalHeight)
	if fitScreen then
		lg.setDefaultFilter("nearest", "nearest")
	end
	viewport.canvas = internalCanvas
end

--- Resize function.
-- Called when the output is resized, can be assigned to <code>love.resize</code>
-- but more likely you will want to do other things too.
-- @param width New width of the screen.
-- @param height New height of the screen.
function viewport.resize(width, height)
	local v = viewport
	outputWidth = width
	outputHeight = height
	v.scale = math.max(1, math.min(width / (internalWidth * pixelScaleX), height / (internalHeight * pixelScaleY)))
	if not fitScreen then
		v.scale = math.floor(v.scale)
	end
	v.offsetX = math.floor((width - internalWidth * v.scale * pixelScaleX) * 0.5)
	v.offsetY = math.floor((height - internalHeight * v.scale * pixelScaleY) * 0.5)
end

--- Draw function.
-- Called when the output is to be drawn; can be assigned
-- to <code>love.draw</code>.  All normal drawing should thusly be draw in
-- the <code>viewport.canvas</code> canvas.
function viewport.draw()
	if not internalCanvas then
		return
	end

	local v = viewport

	lg.push()
	lg.translate(v.offsetX, v.offsetY)
	lg.scale(v.scale * pixelScaleX, v.scale * pixelScaleY)
	lg.draw(internalCanvas, 0, 0)
	lg.pop()

	lg.setCanvas(internalCanvas)
	lg.clear(0, 0, 0)
	lg.setCanvas()
end

return viewport
