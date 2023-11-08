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

func _process(_delta):
	if next_movement_frame != null:
		var next_time = next_movement_frame.time
		var last_time = 0
		var cursor_position = Vector2()
		if last_movement_frame != null:
			last_time = last_movement_frame.time
			cursor_position = last_movement_frame.position
		var time_difference = replay_time - last_time
		var time_gap = next_time - last_time
		cursor_position = cursor_position.lerp(next_movement_frame.position, time_difference / time_gap)
		move_cursor_raw.emit(cursor_position)
