extends Resource
class_name GameSettings

const Setting = preload("res://scripts/settings/Setting.gd")
const Callbacks = preload("res://scripts/settings/SettingsCallbacks.gd")

signal setting_changed

enum ApproachMode {
	DISTANCE_TIME,
	DISTANCE_RATE,
	RATE_TIME
}
enum FadeInMode {
	FADE,
	APPEAR
}
enum FadeOutMode {
	FADE,
	DISAPPEAR,
	DISAPPEAR_NO_WINDOW
}
enum NoteRenderMode {
	MULTIMESH,
	INDIVIDUAL
}
enum NoteSpawnMode {
	PRELOAD,
	ROLLING
}
const SETTINGS_CONFIG = [
	["first_time",Setting.Type.BOOLEAN,true],
	["fps_limit",Setting.Type.INT,0],
	["fullscreen",Setting.Type.BOOLEAN,false],
	["approach",Setting.Type.CATEGORY,[
		["time",Setting.Type.FLOAT,1.0],
		["distance",Setting.Type.FLOAT,50.0],
		["rate",Setting.Type.FLOAT,50.0],
		["mode",Setting.Type.ENUM,ApproachMode,ApproachMode.RATE_TIME]
	]],
	["camera",Setting.Type.CATEGORY,[
		["parallax",Setting.Type.CATEGORY, [
			["camera",Setting.Type.FLOAT,1.0],
			["hud",Setting.Type.FLOAT,0.0],
		]],
		["lock",Setting.Type.BOOLEAN,true],
		["drift",Setting.Type.BOOLEAN,false],
	]],
	["skin",Setting.Type.CATEGORY,[
		["block",Setting.Type.CATEGORY,[
			["mesh",Setting.Type.STRING,"cube"],
			["colorset",Setting.Type.ARRAY,["#ff0000","#00ffff"]],
			["opacity",Setting.Type.FLOAT,1.0],
			["scale",Setting.Type.FLOAT,1.0],
			["fade_in_mode",Setting.Type.ENUM,FadeInMode,FadeInMode.FADE],
			["fade_in_time",Setting.Type.FLOAT,0.25],
			["fade_in_amount",Setting.Type.FLOAT,1.0],
			["fade_out_mode",Setting.Type.ENUM,FadeOutMode,FadeOutMode.DISAPPEAR],
			["fade_out_time",Setting.Type.FLOAT,0.1],
			["fade_out_amount",Setting.Type.FLOAT,1.0]
		]],
		["cursor",Setting.Type.CATEGORY,[
			["scale",Setting.Type.FLOAT,1.0],
			["opacity",Setting.Type.FLOAT,1.0],
			["trail_enabled",Setting.Type.BOOLEAN,false],
			["trail_detail",Setting.Type.INT,100],
			["trail_length",Setting.Type.FLOAT,0.1],
			["trail_distance",Setting.Type.FLOAT,1.0]
		]],
		["background",Setting.Type.CATEGORY,[
			["world",Setting.Type.STRING,"tunnel"],
			["ignore_map",Setting.Type.BOOLEAN,false],
			["full_static",Setting.Type.BOOLEAN,false],
			["static_light",Setting.Type.BOOLEAN,false]
		]]
	]],
	["volume",Setting.Type.CATEGORY,[
		["master",Setting.Type.FLOAT,1.0],
		["music",Setting.Type.FLOAT,1.0],
		["sfx",Setting.Type.FLOAT,1.0]
	]],
	["offset",Setting.Type.CATEGORY,[
		["music",Setting.Type.INT,0],
		["hit_sfx",Setting.Type.INT,0],
		["miss_sfx",Setting.Type.INT,0]
	]],
	["controls",Setting.Type.CATEGORY,[
		["sensitivity",Setting.Type.CATEGORY,[
			["mouse",Setting.Type.FLOAT,1.0],
			["absolute",Setting.Type.FLOAT,1.0]
		]],
		["fov",Setting.Type.INT,70],
		["absolute",Setting.Type.BOOLEAN,false]
	]],
	["folders",Setting.Type.CATEGORY,[
		["maps",Setting.Type.ARRAY,["user://../SoundSpacePlus/maps"]]
	]],
	["advanced",Setting.Type.CATEGORY,[
		["skip",Setting.Type.CATEGORY,[
			["minimum_break_time",Setting.Type.FLOAT,5.0],
			["minimum_skip_time",Setting.Type.FLOAT,2.0]
		]],
		["note_render_mode",Setting.Type.ENUM,NoteRenderMode,NoteRenderMode.INDIVIDUAL],
		["note_spawn_mode",Setting.Type.ENUM,NoteSpawnMode,NoteSpawnMode.PRELOAD]
	]]
]

func _init(config=SETTINGS_CONFIG):
	for setting_config in config:
		var setting = Setting.new(setting_config)
		settings[setting_config[0]] = setting

var settings:Dictionary = {}

func get_setting(property):
	if !settings.has(property): return null
	return settings[property]
func _get(property):
	if !settings.has(property): return null
	if settings[property].type == Setting.Type.CATEGORY: return settings[property]
	return settings[property].value
func _set(property,value):
	if !settings.has(property): return false
	if settings[property].type == Setting.Type.CATEGORY: return false
	settings[property].value = value
	return true

# Saving/loading
static func load_setting(setting, data):
	if setting.type == Setting.Type.CATEGORY:
		if typeof(data) != TYPE_DICTIONARY: return
		for key in data.keys():
			var child_setting = setting.get_setting(key)
			if child_setting != null: load_setting(child_setting,data[key])
		return
	setting.value = data
static func parse_setting(setting):
	if setting.type == Setting.Type.CATEGORY:
		var value = {}
		for key in setting.value.keys():
			value[key] = parse_setting(setting.get_setting(key))
		return value
	return setting.value
static func load_from_file(path:String):
	var new_settings = new()
	var data = {}
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		data = JSON.parse_string(file.get_as_text())
	for key in data.keys():
		var setting = new_settings.get_setting(key)
		if setting != null: load_setting(setting, data[key])
	return new_settings
func save_to_file(path:String):
	var data = {}
	for key in settings.keys():
		data[key] = parse_setting(get_setting(key))
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "	", false))
	file.close()
