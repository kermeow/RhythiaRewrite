extends GameObject
class_name PlayerObject

signal hit
signal missed
signal hit_state_changed
signal score_changed
signal failed
signal skipped

@export_category("Configuration")
var controller:PlayerController:
	set(value):
		if controller == value: return
		controller = value
		controller.player = self
		controller.call_deferred("ready")
		controller.skip_request.connect(_skip_request)
		controller.move_cursor.connect(_move_cursor)
		controller.move_cursor_raw.connect(_move_cursor_raw)
		controller.move_camera_raw.connect(_move_camera_raw)
@export var local_player:bool = false
@export_subgroup("Camera")
@export var camera:Camera3D
@export var absolute_camera:Camera3D
@export var camera_origin:Vector3 = Vector3(0,0,-3.5)
@export_subgroup("Cursor")
@export var cursor:Node3D
@onready var _real_cursor:MeshInstance3D = cursor.get_node("Real")
@onready var _ghost_cursor:MeshInstance3D = cursor.get_node("Ghost")
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
	camera.fov = game.settings.controls.fov
	absolute_camera.fov = game.settings.controls.fov
	if local_player: # and !get_tree().vr_enabled:
		camera.make_current()
		if game.settings.controls.absolute:
			Input.warp_mouse(get_viewport().size*0.5)
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.use_accumulated_input = false
		_move_cursor(Vector2(), false)
	_real_cursor.scale = Vector3.ONE * game.settings.skin.cursor.scale / 2.0
	_ghost_cursor.scale = _real_cursor.scale
	trail.instance_count = 0
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
func _spin_cursor():
	cursor_position = Vector2(camera.position.x,camera.position.y) + Vector2(
		tan(camera.rotation.y),
		tan(camera.rotation.x)
	) * -camera.position.z
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
		camera.rotation_degrees -= Vector3(mouse_movement.y, mouse_movement.x, 0) * 10
		_spin_cursor()

func _process(_delta):
	var difference = cursor_position - clamped_cursor_position
	cursor.position = Vector3(clamped_cursor_position.x,clamped_cursor_position.y,0)
	_ghost_cursor.position = Vector3(difference.x,difference.y,0.01)
	_ghost_cursor.transparency = max(0.5,1-(difference.length_squared()*2))
	if game.settings.skin.cursor.trail_enabled:
		_cursor_trail(_delta)

func _cursor_trail(_delta):
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
				trails.push_front(Transform3D(_real_cursor.basis, position))
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
	var objects = manager.objects_to_process
	for object in objects:
		if game.sync_manager.current_time < object.spawn_time: break
		if object.hit_state != HitObject.HitState.NONE: continue
		if !(object.hittable and object.can_hit): continue
		controller.process_hitobject(object)
func hit_object_state_changed(state:HitObject.HitState, object:HitObject):
	if lock_score: return
	hit_state_changed.emit(object.hit_index, state)
	match state:
		HitObject.HitState.HIT:
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
			missed.emit(object)
			score.misses += 1
			score.combo = 0
			score.sub_multiplier = 0
			score.multiplier -= 1
			if !did_fail: health = maxf(health-1,0)
	score_changed.emit(score,health)
	if health == 0 and !did_fail:
		fail()

func fail():
	if !local_player: return
	did_fail = true
	score.failed = true
	score.failed_at = game.sync_manager.current_time
	if !game.mods.no_fail:
		lock_score = true
		failed.emit()

# Controller Events
func _input(event:InputEvent):
	controller.input(event)
func _skip_request():
	if game.check_skippable():
		game.skip()
		skipped.emit()
func _move_cursor(_position:Vector2, is_absolute:bool=false):
	_preprocess_cursor()
	if is_absolute: _absolute_movement(_position)
	else: _relative_movement(_position)
	_postprocess_cursor()
func _move_cursor_raw(_position:Vector2):
	_preprocess_cursor()
	cursor_position = _position
	_postprocess_cursor()
func _move_camera_raw(_rotation:Vector3, _position:Vector3):
	_preprocess_cursor()
	camera.rotation = _rotation
	camera.position = _position
	_spin_cursor()
	_postprocess_cursor()
