extends Node3D
class_name GameScene

var mods:Mods
var settings:GameSettings

var mapset:Mapset
var map_index:int
var map:Map

@export_category("Game Managers")
@export var sync_manager:SyncManager
@export var object_manager:ObjectManager

@export_category("Other Nodes")
@export var origin:Node3D
@export var player:PlayerObject
@onready var local_player:bool = player.local_player

func setup_managers():
	sync_manager.prepare(self)
	object_manager.prepare(self)

func _ready():
	map = mapset.maps[map_index]

	if sync_manager is AudioSyncManager: sync_manager.audio_stream = mapset.audio
	sync_manager.playback_speed = mods.speed

	setup_managers()
	sync_manager.connect("finished",Callable(self,"finish"))

	call_deferred("ready")

func ready():
	pass
func finish(_failed:bool=false):
	pass

func _next_note():
	var current_time = sync_manager.current_time
	for note in map.notes:
		if note.time > current_time:
			return note
func check_skippable():
	var current_time = sync_manager.current_time
	var next_note = _next_note()
	if !next_note and object_manager.objects_to_process.is_empty(): return true
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
	sync_manager.seek(next_note.time - min(1.5,settings.advanced.skip.minimum_skip_time))
