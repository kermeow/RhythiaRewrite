extends GameObject
class_name PlayerObject

signal hit
signal missed
signal score_changed
signal failed

@export_category("Configuration")
@export var local_player:bool = false
@export var camera_origin:Vector3 = Vector3(0,0,-3.5)

@export_category("Nodes")
@export var camera:Camera3D
@export var absolute_camera:Camera3D
@export var cursor:Node3D
@onready var real:MeshInstance3D = cursor.get_node("Real")
@onready var ghost:MeshInstance3D = cursor.get_node("Ghost")
@export var trail:MultiMesh

var trails:Array = []
var trail_position:Vector3 = Vector3.ZERO
var trail_pre_position:Vector3 = Vector3.ZERO

@onready var score:Score = Score.new()

var health:float = 5
var did_fail:bool = false
var lock_score:bool = false

var cursor_position:Vector2 = Vector2.ZERO
var clamped_cursor_position:Vector2 = Vector2.ZERO

func _ready():
	set_process_input(local_player)
	set_physics_process(local_player)
	trail.instance_count = 0
	if local_player: # and !get_tree().vr_enabled:
		camera.make_current()
		camera.fov = game.settings.controls.fov
		absolute_camera.fov = game.settings.controls.fov
		real.scale = Vector3.ONE * game.settings.skin.cursor.scale / 2.0
		ghost.scale = real.scale
		if game.settings.controls.absolute:
			Input.warp_mouse(get_viewport().size*0.5)
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.use_accumulated_input = false
		_input(InputEventMouseMotion.new())
func _exit_tree():
	if local_player:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Input.use_accumulated_input = true

func _preprocess_cursor():
	var parallax = Vector3(clamped_cursor_position.x,clamped_cursor_position.y,0)
	parallax *= game.settings.camera.parallax.camera
	camera.position = camera_origin + (parallax + camera.basis.z) / 4
func _postprocess_cursor():
	var clamp_value = 1.36875
	clamped_cursor_position = Vector2(
		clamp(cursor_position.x,-clamp_value,clamp_value),
		clamp(cursor_position.y,-clamp_value,clamp_value))
	if game.settings.camera.drift:
		cursor_position = clamped_cursor_position
func _input(event):
	if event.is_action_pressed("skip") and game.check_skippable():
		game.skip()
	var should_process_mouse = event is InputEventMouseMotion
	if should_process_mouse:
		_preprocess_cursor()
#		if Globals.platform == "linux":
#			if !game.settings.controls.absolute: _relative_movement(event.relative)
#		else:
		if game.settings.controls.absolute: _absolute_movement(event.position)
		else: _relative_movement(event.relative)
		_postprocess_cursor()
func _absolute_movement(mouse_position:Vector2):
	var cursor_position_3d = absolute_camera.project_position(mouse_position, -camera.position.z)
	cursor_position = Vector2(cursor_position_3d.x, cursor_position_3d.y)
	if !game.settings.camera.lock:
		var spin_position = cursor_position_3d - camera.position
		camera.rotation.y = atan(spin_position.x / -camera.position.z) + PI
		camera.rotation.x = atan(spin_position.y / -camera.position.z)
func _relative_movement(offset:Vector2):
	var mouse_movement = offset * game.settings.controls.sensitivity.mouse / 100.0
	if game.settings.camera.lock:
		cursor_position -= mouse_movement
	else:
		camera.rotation_degrees -= Vector3(mouse_movement.y,mouse_movement.x,0) * 10
		cursor_position = Vector2(camera.position.x,camera.position.y) + Vector2(
			tan(camera.rotation.y),
			tan(camera.rotation.x)
		) * -camera.position.z

func _process(_delta):
	var display_name = cursor.get_node_or_null("DisplayName")
	if display_name and score.total > 0:
		display_name.get_node("Accuracy").text = "%.2f%%" % (float(score.hits*100)/float(score.total))

	if !local_player: return

	var difference = cursor_position - clamped_cursor_position
	cursor.position = Vector3(clamped_cursor_position.x,clamped_cursor_position.y,0)
	ghost.position = Vector3(difference.x,difference.y,0.01)
	ghost.transparency = max(0.5,1-(difference.length_squared()*2))

	if game.settings.skin.cursor.trail_enabled:
		var now = Time.get_ticks_msec()
		var pre_position = trail_pre_position
		var start_position = trail_position
		var end_position = cursor.position
		var gap = end_position - start_position
		var gap_length = gap.length()
		if gap_length > 0:
			var new_trails = floor(game.settings.skin.cursor.trail_detail*gap_length)
			if new_trails > 0:
				trail_pre_position = start_position
				trail_position = end_position
				var start_diff = start_position - pre_position
				var mid_position = start_position + gap / 2 + start_diff / 2
				var control_1 = start_position.lerp(mid_position,0.2)
				var control_2 = end_position.lerp(mid_position,0.2)
				for i in new_trails:
					var progress = i/new_trails
					trails.push_front(now - _delta * progress)
#					var position = end_position - gap * progress
					var position = start_position.bezier_interpolate(control_1,control_2,end_position,progress)
					trails.push_front(Transform3D(real.basis, position))
		var total_trails = trails.size() / 2
		var remove_trails = 0
		trail.instance_count = total_trails
		for trail_no in total_trails:
			var time = (now - trails[trail_no*2+1])/1000
			var time_alpha = 1 - (time / game.settings.skin.cursor.trail_length)
			var distance_alpha = 1 - (float(trail_no) / (game.settings.skin.cursor.trail_distance * game.settings.skin.cursor.trail_detail))
			var alpha = min(time_alpha, distance_alpha)
			trail.set_instance_color(trail_no, Color(1,1,1,alpha))
			trail.set_instance_transform(trail_no, trails[trail_no*2])
			if alpha < 0: remove_trails += 1
		trails.resize((total_trails - remove_trails)*2)

func _physics_process(_delta):
#	if Globals.platform == "linux" and game.settings.controls.absolute:
#		_preprocess_cursor()
#		_absolute_movement(get_viewport().get_mouse_position())
#		_postprocess_cursor()

	var cursor_hitbox = 0.2625
	var hitwindow = 1.75/30
	var objects = manager.objects_to_process
	for object in objects:
		if game.sync_manager.physics_time < object.spawn_time: break
		if object.hit_state != HitObject.HitState.NONE: continue
		if !(object.hittable and object.can_hit): continue
		var x = abs(object.position.x - clamped_cursor_position.x)
		var y = abs(object.position.y - clamped_cursor_position.y)
		var object_scale = object.global_transform.basis.get_scale()
		var hitbox_x = (object_scale.x + cursor_hitbox) / 2.0
		var hitbox_y = (object_scale.y + cursor_hitbox) / 2.0
		if x <= hitbox_x and y <= hitbox_y:
			object.hit()
		elif object is NoteObject:
			if game.sync_manager.physics_time > (object as NoteObject).note.time + hitwindow:
				object.miss()

func hit_object_state_changed(state:int,object:HitObject):
	if lock_score: return
	match state:
		HitObject.HitState.HIT:
#			if local_player: rpc("replicate_hit",object.id,true)
			hit.emit(object)
			score.hits += 1
			score.combo += 1
			score.sub_multiplier += 1
			if score.sub_multiplier == 10 and score.multiplier < 8:
				score.sub_multiplier = 1
				score.multiplier += 1
			score.score += 25 * score.multiplier
			if !did_fail: health = minf(health+0.625,5)
		HitObject.HitState.MISS:
#			if local_player: rpc("replicate_hit",object.id,false)
			missed.emit(object)
			score.misses += 1
			score.combo = 0
			score.sub_multiplier = 0
			score.multiplier -= 1
			if !did_fail: health = maxf(health-1,0)
	rpc("replicate_score",score.score,score.hits,score.misses,score.combo,health)
	score_changed.emit(score,health)
	if health == 0 and !did_fail:
		fail()

func fail():
	if !local_player: return
	did_fail = true
	score.failed = true
	if !game.mods.no_fail:
		lock_score = true
		failed.emit()

@rpc("authority","call_remote","unreliable")
func replicate_score(_score:int,hits:int,misses:int,combo:int,health:float):
	score.score = _score
	score.hits = hits
	score.misses = misses
	score.combo = combo
	health = health
