extends MultiMeshInstance3D
class_name EditorObjectRenderer

@onready var manager:EditorObjectManager = get_parent()
@onready var editor:EditorScene = manager.editor

func _process(_delta):
	var objects = manager.objects_to_process
	self.render_objects(objects)

func prepare():
	pass
func render_objects(_objects:Array):
	pass
