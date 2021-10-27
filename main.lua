local viewportConfiguration = {
	width = 320,
	height = 200,
}

local inputConfiguration = {
	keyboard = {
		left = {"left", "a"},
		up = {"up", "w"},
		right = {"right", "d"},
		down = {"down", "s"},
	},
	joystick = {
		axis = {
			[1] = {
				names = {"left", "right"},
				threshold = 0.5,
			},
			[2] = {
				names = {"up", "down"},
				threshold = 0.5,
			},
		},
		buttons = {
		},
	},
	touch = {
		controls = {
			{
				kind = "dpad",
				anchor = "ld",
				size = 40,
				gap = 5,
				deadZone = 0.2,
			},
		},
	},
}

local bootstrap = require "bootstrap"
bootstrap("game", viewportConfiguration, inputConfiguration)