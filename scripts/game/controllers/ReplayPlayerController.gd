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
	pass
