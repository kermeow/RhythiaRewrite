extends ObjectManager

var spawn_offset:float = 1.0
var ordered_notes:Array = []

func prepare(_game:GameScene):
	if _game.settings.advanced.note_render_mode == 1:
		$NoteRenderer.free()

	super.prepare(_game)

	append_object(origin.get_node("World"),false)
	append_object(origin.get_node("HUD"),false)

	spawn_offset = game.settings.approach.time * game.mods.speed

	for note in game.map.notes:
		if note.time < game.mods.start_from: continue
		ordered_notes.append(note)
	ordered_notes.sort_custom(func(a,b): return a.time < b.time)
	if game.settings.advanced.note_spawn_mode == 0:
		build_notes(ordered_notes)

func _process(_delta):
	if game.settings.advanced.note_spawn_mode == 1:
		roll_notes(ordered_notes)
	super(_delta)

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
