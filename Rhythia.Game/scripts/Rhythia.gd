extends Node

@onready var playlists:Registry = preload("res://assets/content/Playlists.tres")
@onready var mapsets:Registry = preload("res://assets/content/Mapsets.tres")
@onready var blocks:Registry = preload("res://assets/content/Blocks.tres")
@onready var worlds:Registry = preload("res://assets/content/Worlds.tres")

var settings:GameSettings
var first_time:bool = false

func _ready():
	on_init_complete.connect(_on_init_complete)

	# Android permissions
	if OS.has_feature("android"):
		OS.request_permissions()

	# Load settings
	call_deferred("load_settings")

	# Discord
	Discord.SetActivity("Loading", "Testing the rewrite", false)

# Settings
func load_settings():
	settings = GameSettings.new()
	if FileAccess.file_exists(Globals.Paths.settings):
		settings = GameSettings.load_from_file(Globals.Paths.settings)
	else:
		var platform_default = "res://assets/settings/%s.json" % Globals.platform
		if FileAccess.file_exists(platform_default):
			settings = GameSettings.load_from_file(platform_default)
	first_time = settings.first_time

	var callbacks = GameSettings.Callbacks.new()
	callbacks.tree = get_tree()
	callbacks.window = get_window()
	callbacks.bind_to(settings)
	callbacks.reference()
func save_settings():
	var exec_settings = OS.get_executable_path().get_base_dir().path_join("preferences.json")
	if FileAccess.file_exists(exec_settings): Globals.Paths.settings = exec_settings

	settings.save_to_file(Globals.Paths.settings)

# Init
var _initialised:bool = false
var _thread:Thread
var is_init:bool = true
var loading:bool = false
var warning_seen:bool = false
signal on_init_start
signal on_init_stage
signal on_init_complete

func _on_init_complete():
	is_init = false
	loading = false
func init():
	assert(!loading) #,"Already loading")
	loading = true
	if !_initialised:
		_initialised = true
		_thread = _exec_initialiser(_do_init)
		return
	_thread = _exec_initialiser(_reload)
func _exec_initialiser(initialiser:Callable):
	var thread = Thread.new()
	var err = thread.start(initialiser,Thread.PRIORITY_HIGH)
	assert(err == OK) #,"Thread failed")
	call_deferred("emit_signal","on_init_start",initialiser)
	return thread

func _load_mapsets(reset:bool=false):
	if reset: mapsets.clear()
	if !DirAccess.dir_exists_absolute(Globals.Paths.get("maps")):
		DirAccess.make_dir_recursive_absolute(Globals.Paths.get("maps"))
	call_deferred("emit_signal","on_init_stage","Import content - maps")
	var loader = MapsetLoader.new(mapsets)
	loader.load_from_folder(Globals.Paths.get("maps"))
	for folder in settings.paths.maps:
		if DirAccess.dir_exists_absolute(folder): loader.load_from_folder(ProjectSettings.globalize_path(folder))
func _do_init():
	call_deferred("emit_signal","on_init_stage","Waiting")
	_load_mapsets(true)
	call_deferred("emit_signal","on_init_stage","Update paths")
	Globals.call_deferred("update_paths")
	call_deferred("emit_signal","on_init_complete")
func _reload():
	call_deferred("emit_signal","on_init_stage","Reloading content")
	_load_mapsets(false)
	call_deferred("emit_signal","on_init_complete")

# Game Scene
enum GameType {
	SOLO
}
var selected_mapset:String
var selected_mods:Mods = Mods.new()
var game_scene:Node
func load_game_scene(game_type:int, mapset:Mapset, map_index:int=0):
	var full_mapset = Mapset.read_from_file(mapset.path, true, map_index)
	assert(full_mapset.id == mapset.id)
	selected_mapset = mapset.id
	var scene:Node
	match game_type:
		GameType.SOLO:
			var packed_scene:PackedScene = preload("res://scenes/Game.tscn")
			scene = packed_scene.instantiate()
			scene.mods = selected_mods
			scene.settings = settings.clone()
			scene.mapset = full_mapset
			scene.map_index = map_index
	game_scene = scene
	return scene

func _exit_tree():
	if _thread != null: _thread.wait_to_finish()
