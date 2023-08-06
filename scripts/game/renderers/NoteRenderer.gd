extends ObjectRenderer
class_name NoteRenderer

var mesh:MeshPlus

func prepare():
	multimesh.instance_count = 0
	multimesh.use_colors = true
	mesh = Rhythia.blocks.get_by_id(game.settings.skin.block.mesh)
	multimesh.mesh = mesh.mesh
	for i in multimesh.mesh.get_surface_count():
		var material = multimesh.mesh.surface_get_material(i).duplicate()
		if material is ShaderMaterial:
			material.set_shader_parameter("use_color_param", false)
		multimesh.mesh.surface_set_material(i, material)
	multimesh.instance_count = 64

func render_objects(objects:Array):
	var notes = []
	for object in objects:
		if game.sync_manager.current_time < object.spawn_time: break
		if not object is NoteObject: continue
		if !object.visible: continue
		notes.append(object)

	var count = notes.size()
	if count > multimesh.instance_count: multimesh.instance_count = count
	multimesh.visible_instance_count = count

	for i in count:
		var note = notes[count-(i+1)]
		multimesh.set_instance_color(i,note.mixed_colour)
		multimesh.set_instance_transform(i,note.global_transform.translated(mesh.offset))
