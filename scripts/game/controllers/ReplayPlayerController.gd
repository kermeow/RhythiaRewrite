extends PlayerController

var replay_time:float = 0

var next_frame:Replay.Frame
var last_frame:Replay.Frame

var next_movement_frame:Replay.Frame
var last_movement_frame:Replay.Frame

var unhandled_hit_frames:Array[Replay.HitStateFrame] = []
var passed_frames:Array[Replay.Frame] = []

func set_next_frame(frame:Replay.Frame):
	passed_frames.append(frame)
	if is_instance_of(frame, Replay.HitStateFrame):
		unhandled_hit_frames.append(frame)
	if is_instance_of(frame, Replay.CameraRotationFrame) or is_instance_of(frame, Replay.CursorPositionFrame):
		last_movement_frame = next_movement_frame
		next_movement_frame = frame
	last_frame = next_frame
	next_frame = frame

func process_hitobject(object:HitObject):
	var frame
	for _frame in unhandled_hit_frames:
		if _frame.object_index == object.hit_index:
			frame = _frame
			break
	if frame == null: return
	object.hit_state = frame.hit_state
	unhandled_hit_frames.erase(frame)

func _process(_delta):
	if next_movement_frame != null:
		if game.settings.camera.lock: _process_lock()
		else: _process_spin()
func _process_lock():
	var next_time = next_movement_frame.time
	var last_time = 0
	var position = Vector2()
	if last_movement_frame != null:
		last_time = last_movement_frame.time
		position = last_movement_frame.position
	var time_difference = replay_time - last_time
	var time_gap = next_time - last_time
	var t = minf(time_difference / time_gap, 1)
	position = position.lerp(next_movement_frame.position, t)
	move_cursor_raw.emit(position)
func _process_spin():
	var next_time = next_movement_frame.time
	var last_time = 0
	var position = Vector3()
	var rotation = Vector3(0,-180,0)
	if last_movement_frame != null:
		last_time = last_movement_frame.time
		position = last_movement_frame.position
		rotation = last_movement_frame.rotation
	var time_difference = replay_time - last_time
	var time_gap = next_time - last_time
	var t = minf(time_difference / time_gap, 1)
	position = position.lerp(next_movement_frame.position, t)
	rotation = Vector3(
		lerp_angle(rotation.x, next_movement_frame.rotation.x, t),
		lerp_angle(rotation.y, next_movement_frame.rotation.y, t),
		lerp_angle(rotation.z, next_movement_frame.rotation.z, t)
	)
	move_camera_raw.emit(rotation, position)
