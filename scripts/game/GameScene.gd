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
	
	build_map()

	call_deferred("ready")

func build_map():
	var objects = []
	for note in map.notes:
		if note.time < mods.start_from: continue
		var object = build_note(note)
		objects.append(object)
	objects.sort_custom(func(a,b): return a.spawn_time < b.spawn_time)
	for object in objects:
		object_manager.append_object(object)

func build_note(note:Map.Note):
	var id = note.data.get("id","note-%s" % note.index)
	var object = NoteObject.new(id,note)
	object.name = id
	var colorset = settings.skin.block.colorset
	var colour_index = wrapi(note.index,0,colorset.size())
	var colour = colorset[colour_index]
	object.colour = Color.from_string(colour,Color.RED)
	object.spawn_distance = settings.approach.distance
	object.hittable = true
	object.spawn_time = note.time - (settings.approach.time * mods.speed)
	object.despawn_time = note.time + 1
	object.visible = false
	return object

func ready():
	pass
func finish(_failed:bool=false):
	pass
