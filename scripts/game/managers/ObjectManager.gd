extends GameManager
class_name ObjectManager

var origin

signal object_spawned
signal object_despawned

var objects:Array[GameObject] = []
var objects_ids:Dictionary = {}
var objects_to_process:Array[GameObject]

var last_hit_index:int = 0

var spawn_offset:float = 1.0
var ordered_notes:Array = []

var player:PlayerObject

func _post_ready():
	if game.settings.advanced.note_render_mode == 1:
		$NoteRenderer.free()
	else:
		$NoteRenderer.prepare()

	origin = game.origin
	player = game.player

	origin.set_physics_process(game.local_player)

	append_object(player,false)

	append_object(origin.get_node("World"),false)
	append_object(origin.get_node("HUD"),false)

	spawn_offset = game.settings.approach.time * game.mods.speed

	for note in game.map.notes:
		if note.time < game.mods.seek: continue
		ordered_notes.append(note)
	ordered_notes.sort_custom(func(a,b): return a.time < b.time)
	if game.settings.advanced.note_spawn_mode == 0:
		build_notes(ordered_notes)

func append_object(object:GameObject,parent:bool=true,include_children:bool=false):
	if objects_ids.keys().has(object.id): return false

	object.game = game
	object.manager = self

	object.set_physics_process(game.local_player)
	if !object.permanent: object.process_mode = Node.PROCESS_MODE_DISABLED
	object.process_priority = 4

	if object is HitObject:
		object.hit_index = last_hit_index
		last_hit_index += 1
		if player != null: object.connect(
			"on_hit_state_changed",
			player.hit_object_state_changed.bind(object)
		)

	if parent: # Reparent to origin
		var current_parent = object.get_parent()
		if current_parent != origin:
			if current_parent != null:
				current_parent.remove_child(object)
			origin.add_child(object)

	if include_children: # Append children
		for child in object.get_children():
			if child is GameObject:
				append_object(child,false,true)

	objects.append(object)
	objects_ids[object.id] = object
	if !object.permanent: objects_to_process.append(object)

func _process(_delta):
	if game.settings.advanced.note_spawn_mode == 1:
		roll_notes(ordered_notes)
	for object in objects_to_process.duplicate():
		if game.sync_manager.current_time < object.spawn_time: break
		if object.force_despawn or game.sync_manager.current_time > object.despawn_time:
			object.despawned.emit()
			object_despawned.emit(object)
			if object is HitObject and object.hit_state == HitObject.HitState.NONE:
				object.miss()
			object.process_mode = Node.PROCESS_MODE_DISABLED
			objects_to_process.erase(object)
			continue
		if object.process_mode != Node.PROCESS_MODE_INHERIT:
			object.spawned.emit()
			object_spawned.emit(object)
		object.process_mode = Node.PROCESS_MODE_INHERIT

func roll_notes(notes:Array):
	var total_notes = notes.size()
	if total_notes == 0: return
	if game.sync_manager.current_time < notes[0].time - spawn_offset: return
	while notes.size() > 0:
		var note = notes.pop_front()
		append_object(build_note(note))
		if game.sync_manager.current_time + 0.1 < note.time - spawn_offset: break

func build_notes(notes:Array):
	var objects = []
	for note in notes:
		var object = build_note(note)
		objects.append(object)
	objects.sort_custom(func(a,b): return a.spawn_time < b.spawn_time)
	for object in objects:
		append_object(object)

func build_note(note:Map.Note):
	var id = note.data.get("id","note-%s" % note.index)
	var object = NoteObject.new(id,note)
	object.name = id
	var colorset = game.settings.skin.block.colorset
	var colour_index = wrapi(note.index,0,colorset.size())
	var colour = colorset[colour_index]
	object.colour = Color.from_string(colour,Color.RED)
	object.spawn_distance = game.settings.approach.distance
	object.hittable = true
	object.spawn_time = note.time - spawn_offset
	object.despawn_time = note.time + 1
	object.visible = false
	if game.settings.advanced.note_render_mode == 1:
		var renderer = IndividualNoteRenderer.new()
		object.add_child(renderer)
	return object
