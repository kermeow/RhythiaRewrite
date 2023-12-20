extends Node3D
class_name GameScene

var mods:Mods
var settings:GameSettings

var mapset:Mapset
var map_index:int
var map:Map

var replay:Replay

@export_category("Game Managers")
@export var sync_manager:SyncManager
@export var object_manager:ObjectManager
@export var replay_manager:ReplayManager
@export var hud_manager:HUDManager
@export var reporter:StatisticsReporter

@export_category("Other Nodes")
@export var origin:Node3D
@export var world_parent:WorldContainerObject
@export var player:PlayerObject
@onready var local_player:bool = player.local_player

func _ready():
	if replay != null:
		mods = replay.mods
		replay.read_settings(settings)
		replay_manager.mode = ReplayManager.Mode.PLAY
		replay_manager.replay = replay
		var replay_controller = PlayerController.ReplayController.new()
		player.controller = replay_controller
		call_deferred("add_child", replay_controller)
	else:
		var solo_controller = PlayerController.SoloController.new()
		player.controller = solo_controller
		call_deferred("add_child", solo_controller)
		replay = replay_manager.replay

	map = mapset.maps[map_index]

	Discord.SetActivity("%s" % map.name, mapset.name, true)

	if sync_manager is AudioSyncManager: sync_manager.audio_stream = mapset.audio
	sync_manager.playback_speed = mods.speed

	var world = Rhythia.get("worlds").items.front()
	var selected_world = settings.skin.background.world
	var ids = Rhythia.get("worlds").get_ids()
	if ids.has(selected_world):
		world = Rhythia.get("worlds").get_by_id(selected_world)
	if world != null:
		world_parent.call_deferred("load_world", world)

	HitObject.hit_sound = $Hit
	HitObject.miss_sound = $Miss

#	reporter.start()
	replay_manager.start()

	player.connect("failed",finish.bind(true))

	sync_manager.connect("finished",Callable(self,"finish"))
	sync_manager.call_deferred("start", mods.seek - (settings.approach.time + 1.5) * sync_manager.playback_speed)

var ended:bool = false
func finish(failed:bool=false):
	if ended: return
	ended = true
#	reporter.stop()
	replay_manager.stop()
	if Globals.debug: print("failed: %s" % failed)
	if failed:
		if Globals.debug: print("fail animation")
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sync_manager,"playback_speed",0,1)
		tween.play()
		await tween.finished
	else:
		if Globals.debug: print("pass")
		$PauseHandler.process_mode = Node.PROCESS_MODE_DISABLED
		$PauseHandler/Control.visible = false
		await get_tree().create_timer(0.5).timeout
	var packed_results:PackedScene = preload("res://scenes/Results.tscn")
	var results:ResultsScreen = packed_results.instantiate()
	var image = get_viewport().get_texture().get_image() # hacky screenshot
	results.screenshot = ImageTexture.create_from_image(image)
	results.mapset = mapset
	results.map_index = map_index
	results.score = player.score
	results.mods = mods
#	results.statistics = reporter.statistics
	results.settings = settings
	get_tree().change_scene_to_node(results)

func _next_note():
	var current_time = sync_manager.current_time
	for note in map.notes:
		if note.time > current_time:
			return note
func check_skippable():
	var current_time = sync_manager.current_time
	var next_note = _next_note()
	if !next_note: return object_manager.objects_to_process.is_empty()
	var next_note_time = next_note.time
	var last_note_time = 0
	if map.notes.find(next_note) > 0:
		last_note_time = map.notes[map.notes.find(next_note)-1].time
	var is_break = (next_note_time - last_note_time) >= settings.advanced.skip.minimum_break_time
	if !is_break: return false
	return (next_note_time - current_time) > settings.advanced.skip.minimum_skip_time
func skip():
	var current_time = sync_manager.current_time
	var next_note = _next_note()
	if next_note:
		var skip_time = next_note.time - min(1.5,settings.advanced.skip.minimum_skip_time)
		sync_manager.seek(skip_time)
		return
	finish()
