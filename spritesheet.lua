--- Spritesheet builder helper module.
-- This module is specific to LÖVE2D.<br/>
-- Used to create image-quad configurations to load various parts of an image
-- as a spritesheet.
local lg = love.graphics

local imgCache = {}
local spritesheet = {}

local function getImage(fileName, imgCache)
	local entry = imgCache[fileName]
	if entry then
		return unpack(entry)
	end	

	local idata = love.image.newImageData(fileName)
	local image = lg.newImage(idata)
	imgCache[fileName] = {image, idata}

	return image, idata
end

--- Build an image - quads configuration.
-- Given a config parameter, build a series of tables that contain the quad
-- information, along with an image name and its size.<br/>
-- The input config should be of the following form:
-- <ul>
--   <li><b>fileName</b>: The image file to take work on.</li>
--   <li><b>quadGen</b>: The quad configuration; it's as follows:
--     <ul>
--       <li>&lt;quadGroupName&gt;: &lt;quadConfSpec&gt;</li>
--     </ul>
--   </li>
--   <li><b>imageCache</b>(optional): When given uses this as the image cache,
--     instead of the internal one.</li>
-- </ul>
-- Where <b>&lt;quadConfSpec&gt;</b> looks like:
-- <ul>
--   <li>w: Mandatory width.</li>
--   <li>h: Mandatory height.</li>
--   <li>x: X start position (default: 0).</li>
--   <li>y: Y start position (default: 0).</li>
--   <li>n: Total number of tiles to extract (default: 1).</li>
--   <li>c: Tiles per row (default: n).</li>
--   <li>gx: Horizontal gap between tiles (default: 0).</li>
--   <li>gy: Vertical gap between tiles (default: 0).</li>
--   <li>l: Labels (optional); when given, also label the tiles in the output.</li>
-- </ul>
-- Here's an example of the output of this function:
-- <pre>
-- <code>
--   {
--     "&lt;quadGroupName&gt;" = {
--       &lt;quad1&gt;,
--       &lt;quad2&gt;,
--       &lt;quad3&gt;,
--       [...]
--       &lt;quadn&gt;,
--       "&lt;optionalQuadName3&gt;" = &lt;quad3&gt;,
--       "&lt;optionalQuadName1&gt;" = &lt;quad1&gt;,
--     },
--     [...]
--     "&lt;otherQuadGroupName&gt;" = &lt;otherQuadSpec&gt;,
--   }
-- </code>
-- </pre>
-- @param config The configuration.
-- @return The mentioned output.
function spritesheet.build(config)
	if not (config and config.fileName) then
		error("fileName missing from spritesheet config", 2)
	end

	local image, idata = getImage(config.fileName, config.imageCache or imgCache)
	local iw, ih = image:getDimensions()

	local sprs = {
		image = image,
		imageData = idata,
		width = iw,
		height = ih,
	}

	if config.quadGen then
		local quads = {}

		for k, v in pairs(config.quadGen) do
			local x = v.x or 0
			local y = v.y or 0
			local w = v.w or error("Width (w) not given for quad '"..k.."'")
			local h = v.h or error("Height (h) not given for quad '"..k.."'")
			local total = v.n or 1
			local cellsPerRow = v.c or total
			local gapX = v.gx or 0
			local gapY = v.gy or 0
			local labels = v.l or {}
			local qs = {}
			local i = 0
			local o = x
			while i < total do
				local quad = lg.newQuad(o, y, w, h, iw, ih)
				qs[#qs+1] = quad
				i = i + 1
				local label = labels[i]
				if label then
					qs[label] = quad
				end
				o = o + w + gapX
				if i % cellsPerRow == 0 then
					y = y + h + gapY
					o = x
				end
			end
			quads[k] = qs
		end

		sprs.quads = quads
	end

	return sprs
end

--- Break the internal cache.
function spritesheet.breakCache()
	imgCache = {}
end

return spritesheet
