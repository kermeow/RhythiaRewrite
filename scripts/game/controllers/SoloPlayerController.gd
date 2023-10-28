extends PlayerController

func _input(event):
	if event.is_action_pressed("skip"):
		skip_request.emit()
	if event is InputEventMouseMotion:
		var is_absolute = game.settings.controls.absolute
		var position = event.position if is_absolute else event.relative
		move_cursor.emit(position, is_absolute)
