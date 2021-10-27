function love.conf(t)
	t.identity = "fkbm-labyrinth"
	t.version = "11.0"
	t.accelerometerjoystick = false
	t.externalstorage = true
	t.gammacorrect = true

	local w = t.window
	w.title = "Labyrinth"
	w.icon = nil
	w.width = 720
	w.height = 480
	w.minwidth = 360
	w.minheight = 240
	w.resizable = true
	w.usedpiscale = false
	w.hidpi = false
	w.fullscreentype = "desktop"
	w.fullscreen = false
end
