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
