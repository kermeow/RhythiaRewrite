extends MeshInstance3D
class_name IndividualNoteRenderer

@onready var note:NoteObject = get_parent()
@onready var game:GameScene = note.game

var mesh_plus:MeshPlus
var color:Color:
	set(value):
		color = Color(value, 1.0)
		transparency = 1.0 - note.mixed_colour.a
		for i in mesh.get_surface_count():
			var material = get_surface_override_material(i)
			if material is ShaderMaterial:
				material.set_shader_parameter("use_color_param", true)
				material.set_shader_parameter("color", color)
			else:
				material.vertex_color_use_as_albedo = false
				material.albedo_color = color

func _ready():
	mesh_plus = Rhythia.blocks.get_by_id(game.settings.skin.block.mesh)
	mesh = mesh_plus.mesh
	for i in mesh.get_surface_count():
		set_surface_override_material(i, mesh.surface_get_material(i).duplicate())
	color = note.colour
	transparency = 1
	scale_object_local(Vector3.ONE * game.settings.skin.block.scale)
	translate_object_local(mesh_plus.offset)

func _process(delta):
	color = note.mixed_colour
