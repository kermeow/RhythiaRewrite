extends ObjectManager

func prepare(_game:GameScene):
	if _game.settings.advanced.note_render_mode == 1:
		$NoteRenderer.free()
	
	super.prepare(_game)
	
	append_object(origin.get_node("World"),false)
	append_object(origin.get_node("HUD"),false)
	
	if game.settings.advanced.note_spawn_mode == 0:
		build_map(game.map)

func build_map(map:Map):
	var objects = []
	for note in map.notes:
		if note.time < game.mods.start_from: continue
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
	object.spawn_time = note.time - (game.settings.approach.time * game.mods.speed)
	object.despawn_time = note.time + 1
	object.visible = false
	if game.settings.advanced.note_render_mode == 1:
		var renderer = IndividualNoteRenderer.new()
		object.add_child(renderer)
	return object
