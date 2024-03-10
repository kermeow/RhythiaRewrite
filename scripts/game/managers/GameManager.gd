extends Node
class_name GameManager

@onready var game:GameScene = _find_game()

func _find_game():
	var _game:GameScene
	var target = get_parent()
	while _game == null and target != null:
		if target is GameScene:
			_game = target
			break
		target = target.get_parent()
	assert(_game != null, "GameManagers must be under a GameScene")
	return _game

func _ready():
	_post_ready.call_deferred()
func _post_ready():
	pass
