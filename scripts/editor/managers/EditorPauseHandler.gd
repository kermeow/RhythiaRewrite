extends EditorManager

func _input(event):
	var paused = get_tree().paused
	if event.is_action_pressed("skip"):
		if !paused: attempt_pause()
		else: attempt_resume()

var tween:Tween
func attempt_pause():
	if get_tree().paused: return
	print("Pausing")
	get_tree().paused = true
func attempt_resume():
	if !get_tree().paused: return
	print("Resuming")
	get_tree().paused = false
