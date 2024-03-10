extends Control

var replays:Array = []
var paths:Dictionary = {}
var dates:Dictionary = {}

@onready var button_container = $Items
@onready var origin_button = $Items/Button

var buttons = []

func _ready():
	button_container.remove_child(origin_button)
	_load_replays()
	_create_buttons()
	_update_buttons()

func _load_replays():
	if !DirAccess.dir_exists_absolute(Globals.Paths.replays):
		DirAccess.make_dir_recursive_absolute(Globals.Paths.replays)
	var dir = DirAccess.open(Globals.Paths.replays)
	for file in dir.get_files():
		var full_path = Globals.Paths.replays.path_join(file)
		var replay = Replay.read_from_file(full_path)
		replays.append(replay)
		paths[replay] = full_path
		dates[replay] = FileAccess.get_modified_time(full_path)
	replays.sort_custom(func(a,b): return dates[a] > dates[b])

func _create_buttons():
	if buttons.size() > replays.size():
		for i in buttons.size() - replays.size():
			buttons.pop_back().free()
		return
	for i in replays.size() - buttons.size():
		var button = origin_button.duplicate()
		button_container.add_child(button)
		buttons.append(button)
		button.get_node("Buttons/Play").pressed.connect(_play_pressed.bind(button))
		button.get_node("Buttons/Delete").pressed.connect(_delete_pressed.bind(button))
func _update_button(button, replay:Replay):
	button.set_meta("replay", replay)
	var mapset = replay.mapset
	button.get_node("Cover/Image").texture = mapset.cover
	button.get_node("Title").text = mapset.name
	button.get_node("Player").text = "%s - %s" % [
		replay.player_name,
		Time.get_datetime_string_from_unix_time(dates[replay], true)
	]
	var score = replay.score
	button.get_node("Score/Score").text = HUDManager.comma_sep(score.score)
	button.get_node("Score/Accuracy").text = "%.2f%%" % (float(score.hits*100)/float(score.total))
	button.get_node("Score/Failed").visible = score.failed
func _update_buttons():
	for i in buttons.size():
		var button = buttons[i]
		if i >= replays.size():
			button.visible = false
			continue
		button.visible = true
		var replay = replays[i]
		_update_button(button, replay)
func _play_pressed(button):
	var replay = button.get_meta("replay")
	var mapset:Mapset = replay.mapset
	var index = mapset.get_index_by_id(replay.map_id)
	var scene = Rhythia.load_game_scene(Rhythia.GameType.SOLO, mapset, index)
	scene.replay = replay
	get_tree().change_scene_to_node(scene)
func _delete_pressed(button):
	var replay = button.get_meta("replay")
	replays.erase(replay)
	DirAccess.remove_absolute(paths[replay])
	button.queue_free()
