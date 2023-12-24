extends EditorManager

func _input(event):
	var paused = get_tree().paused
	if event.is_action_pressed("skip"):
		if !paused: attempt_pause()
		else: attempt_resume()
	if event.is_action_pressed("editorReturn"):
		attempt_return()

func attempt_pause():
	if get_tree().paused: return
	print("Pausing")
	get_tree().paused = true
func attempt_resume():
	if !get_tree().paused: return
	print("Resuming")
	get_tree().paused = false
func attempt_return():
#	if !get_tree().paused: return
	print("Returning")
	editor.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
