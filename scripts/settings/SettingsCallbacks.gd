var settings:GameSettings

var tree:SceneTree
var window:Window

func bind_to(_settings:GameSettings):
	settings = _settings

	# Skin
	settings.skin.background.get_setting("full_static").changed.connect(full_static)

	# Approach Rate
	settings.approach.get_setting("rate").changed.connect(approach_rate.bind("rate"))
	settings.approach.get_setting("time").changed.connect(approach_rate.bind("time"))
	settings.approach.get_setting("distance").changed.connect(approach_rate.bind("distance"))

	# Volume
	settings.volume.get_setting("master").changed.connect(volume.bind("Master"))
	settings.volume.get_setting("music").changed.connect(volume.bind("Music"))
	settings.volume.get_setting("sfx").changed.connect(volume.bind("SFX"))

	# FPS
	settings.get_setting("fps_limit").changed.connect(set_fps)

	# Fullscreen
	settings.get_setting("fullscreen").changed.connect(fullscreen)
	
	# Gui Scale
	settings.get_setting("gui_scale").changed.connect(gui_scale)

func full_static(value:bool):
	if value:
		settings.skin.background.static_light = true

func approach_rate(_value,value:String):
	var mode = settings.approach.mode
	match mode:
		GameSettings.ApproachMode.DISTANCE_TIME:
			if value == "rate": return
			settings.approach.rate = settings.approach.distance / settings.approach.time
		GameSettings.ApproachMode.DISTANCE_RATE:
			if value == "time": return
			settings.approach.time = settings.approach.distance / settings.approach.rate
		GameSettings.ApproachMode.RATE_TIME:
			if value == "distance": return
			settings.approach.distance = settings.approach.rate * settings.approach.time

var pre_fullscreen_size:Vector2
var pre_fullscreen_mode:int
func fullscreen(value:bool):
	if value and window.mode != Window.MODE_EXCLUSIVE_FULLSCREEN:
		pre_fullscreen_size = window.size
		pre_fullscreen_mode = window.mode
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	elif window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = pre_fullscreen_mode
		window.size = pre_fullscreen_size

func volume(value:float,bus:String="Master"):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus),linear_to_db(value))

func set_fps(value:int):
	tree.fps_limit = value

func gui_scale(value:int):
	var scale = 1
	match value:
		0: scale = 1.6 # 1280 / 800
		1: scale = 1
		2: scale = 0.8 # 1280 / 1600
		3: scale = 1280.0 / 1920.0
		4: scale = 0.5 # 1280 / 2560
#	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
#	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_factor = scale
