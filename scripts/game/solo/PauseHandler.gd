extends Control

var cooldown = 0
var mouse_position
var mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready():
	modulate.a = 0
	mouse_filter = Control.MOUSE_FILTER_PASS
	visible = true
	$Panel/Buttons/Resume.connect("pressed",Callable(self,"attempt_resume"))
	$Panel/Buttons/Restart.connect("pressed",Callable(self,"attempt_restart"))
	$Panel/Buttons/Return.connect("pressed",Callable(self,"attempt_return"))

func _input(event):
	var paused = get_tree().paused
	if event.is_action_pressed("pause"):
		if !(event.is_action_pressed("skip") and get_parent().check_skippable()) and !paused: attempt_pause()
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
	mouse_position = get_global_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_filter = Control.MOUSE_FILTER_STOP
	Input.warp_mouse(get_viewport_rect().size*0.5)
	if tween != null: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self,"modulate:a",1,0.4)
	tween.play()
func attempt_resume():
	if !get_tree().paused: return
	print("Resuming")
	var now = Time.get_ticks_msec()
	cooldown = now
	Input.mouse_mode = mouse_mode
	Input.warp_mouse(mouse_position)
	mouse_filter = Control.MOUSE_FILTER_PASS
	if tween != null: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self,"modulate:a",0,0.4)
	tween.play()
	await get_tree().create_timer(0.4).timeout
	await tween.finished
	get_tree().paused = false
func attempt_restart():
	if !get_tree().paused: return
	print("Restarting")
	mouse_filter = Control.MOUSE_FILTER_PASS
	get_parent().process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	var game_scene = Rhythia.load_game_scene(Rhythia.GameType.SOLO,get_parent().mapset,get_parent().map_index)
	get_tree().change_scene_to_node(game_scene)
func attempt_return():
	if !get_tree().paused: return
	print("Returning")
	get_parent().process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")
