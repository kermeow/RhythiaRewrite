extends GameManager

var cooldown = 0
var mouse_position
var mouse_mode = Input.MOUSE_MODE_CAPTURED

func _post_ready():
	$Control.modulate.a = 0
	$Control.mouse_filter = Control.MOUSE_FILTER_PASS
	$Control.visible = true
	$Control/Panel/Buttons/Resume.pressed.connect(attempt_resume)
	$Control/Panel/Buttons/Restart.pressed.connect(attempt_restart)
	$Control/Panel/Buttons/Return.pressed.connect(attempt_return)

func _input(event):
	var paused = get_tree().paused
	if event.is_action_pressed("pause"):
		var is_skip_event = event.is_action_pressed("skip") and game.check_skippable()
		if Globals.debug:
			print(event.is_action_pressed("skip"))
			print(game.check_skippable())
			print(is_skip_event)
		if !is_skip_event and !paused: attempt_pause()
		else: attempt_resume()
	if event.is_action_pressed("restart"):
		get_tree().paused = true
		attempt_restart()

var tween:Tween
func attempt_pause():
	if get_tree().paused: return
	print("Pausing")
	var now = Time.get_ticks_msec()
	if (now - cooldown) < 150: return
	get_tree().paused = true
	mouse_mode = Input.mouse_mode
	mouse_position = $Control.get_global_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$Control.mouse_filter = Control.MOUSE_FILTER_STOP
	Input.warp_mouse($Control.get_viewport_rect().size*0.5)
	if tween != null: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Control,"modulate:a",1,0.15)
	tween.play()
func attempt_resume():
	if !get_tree().paused: return
	print("Resuming")
	var now = Time.get_ticks_msec()
	cooldown = now
	Input.mouse_mode = mouse_mode
	Input.warp_mouse(mouse_position)
	$Control.mouse_filter = Control.MOUSE_FILTER_PASS
	if tween != null: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Control,"modulate:a",0,0.15)
	tween.play()
	await get_tree().create_timer(0.15).timeout
	await tween.finished
	get_tree().paused = false
func attempt_restart():
	if !get_tree().paused: return
	print("Restarting")
	$Control.mouse_filter = Control.MOUSE_FILTER_PASS
	game.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	var game_scene = Rhythia.load_game_scene(Rhythia.GameType.SOLO,game.mapset,game.map_index)
	if game.replay_manager.mode == ReplayManager.Mode.PLAY:
		game_scene.replay = game.replay
	get_tree().change_scene_to_node(game_scene)
func attempt_return():
	if !get_tree().paused: return
	print("Returning")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
