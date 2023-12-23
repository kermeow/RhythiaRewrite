extends EditorPlayerController

func input(event):
	if event.is_action_pressed("skip"):
		skip_request.emit()
	if event is InputEventMouseMotion:
		var is_absolute = editor.settings.controls.absolute
		var position = event.position if is_absolute else event.relative
		move_cursor.emit(position, is_absolute)
func process_hitobject(object:EditorHitObject):
	var cursor_hitbox = 0.2625
	var hitwindow = 1.75/30
	var cursor_position = player.clamped_cursor_position
	var x = abs(object.position.x - cursor_position.x)
	var y = abs(object.position.y - cursor_position.y)
	var object_scale = object.global_transform.basis.get_scale()
	var hitbox_x = (object_scale.x + cursor_hitbox) / 2.0
	var hitbox_y = (object_scale.y + cursor_hitbox) / 2.0
	if x <= hitbox_x and y <= hitbox_y:
		object.hit()
	elif object is EditorNoteObject:
		if editor.sync_manager.current_time > (object as EditorNoteObject).note.time + hitwindow:
			object.miss()
