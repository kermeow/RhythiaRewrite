extends Button

var replay_exists:bool = false
var replay:Replay

func _ready():
	replay_exists = FileAccess.file_exists("user://recent.rhyr")
	disabled = !replay_exists
	if replay_exists:
		replay = Replay.read_from_file("user://recent.rhyr")

func _pressed():
	var mapset:Mapset = Rhythia.mapsets.get_by_id(replay.mapset_id)
	var index = mapset.get_index_by_id(replay.map_id)
	var scene = Rhythia.load_game_scene(Rhythia.GameType.SOLO, mapset, index)
	scene.replay = replay
	get_tree().change_scene_to_node(scene)
