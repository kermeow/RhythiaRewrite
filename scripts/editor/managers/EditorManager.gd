extends Node
class_name EditorManager

@onready var editor:EditorScene = _find_editor()

func _find_editor():
	var _editor:EditorScene
	var target = get_parent()
	while _editor == null and target != null:
		if target is EditorScene:
			_editor = target
			break
		target = target.get_parent()
	assert(_editor != null, "EditorManagers must be under a EditorScene")
	return _editor

func _ready():
	_post_ready.call_deferred()
func _post_ready():
	pass
