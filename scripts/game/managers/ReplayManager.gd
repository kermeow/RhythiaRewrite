extends GameManager
class_name ReplayManager

enum Mode {
	RECORD,
	PLAY
}
@export var mode:Mode

var replay:Replay = Replay.new()
var active:bool = false
var start_time:int = 0

var record_rate:int = 60

func start():
	assert(!active)
	active = true
	start_time = Time.get_ticks_msec()
	game.player.hit_state_changed.connect(record_hit_frame)
func stop():
	if !active: return
	active = false

func _process(_delta):
	if !active: return
	match mode:
		_, Mode.RECORD: record_frame()

func record_hit_frame(object_index:int, hit_state:HitObject.HitState):
	var frame = Replay.HitStateFrame.new()
	frame.object_index = object_index
	frame.hit_state = hit_state
	_record_frame(frame, true)
	record_frame(true)
var _last_cursor_position:Vector2 = Vector2()
func record_frame(important:bool=false):
	var cursor_position = game.player.cursor_position
	if cursor_position == _last_cursor_position: return
	_last_cursor_position = cursor_position
	var frame:Replay.Frame
	if game.settings.camera.lock:
		frame = Replay.CursorPositionFrame.new()
		frame.position = cursor_position
	else:
		frame = Replay.CameraRotationFrame.new()
		frame.position = game.player.camera.position
		var rotation = game.player.camera.rotation_degrees
		frame.rotation = Vector3(
			wrapf(rotation.x, 0, 360),
			wrapf(rotation.y, 0, 360),
			wrapf(rotation.z, 0, 360)
		)
	_record_frame(frame, important)
func _record_frame(frame:Replay.Frame, important:bool=false): # I stole this concept from osu
	var should_record = important
	var now = (Time.get_ticks_msec() - start_time) / 1000.0
	if replay.frames.size() > 0 and !important:
		var last_frame = replay.frames.back()
		should_record = now - last_frame.time >= 1.0 / record_rate
	if !should_record: return false
	frame.time = now
	replay.frames.append(frame)
	return true
