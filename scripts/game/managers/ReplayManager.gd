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
	match mode:
		_, Mode.RECORD:
			game.player.hit_state_changed.connect(record_hit_frame)
			if Globals.debug: print("Recording new replay")
			replay.mapset_id = game.mapset.id
			replay.map_id = game.map.id
			replay.mods = game.mods
			replay.score = game.player.score
		Mode.PLAY:
			if Globals.debug: print("Playing replay")
func stop():
	if !active: return
	active = false
	if Globals.debug: print("Stopping replay")
	match mode:
		_, Mode.RECORD:
			replay.write_to_file("user://recent.rhyr")
		Mode.PLAY:
			pass

func _process(_delta):
	if !active: return
	match mode:
		_, Mode.RECORD: record_frame()
		Mode.PLAY:
			var controller = game.player.controller
			var now = (Time.get_ticks_msec() - start_time) / 1000.0
			controller.replay_time = now
			var next_frame = controller.next_frame
			if next_frame == null: controller.set_next_frame(replay.frames[0])
			while next_frame.time < now:
				next_frame = replay.frames[next_frame.index + 1]
				controller.set_next_frame(next_frame)

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
		var rotation = game.player.camera.rotation_degrees
		frame.rotation = Vector3(
			fposmod(rotation.x, 360),
			fposmod(rotation.y, 360),
			fposmod(rotation.z, 360)
		)
		frame.position = game.player.camera.position
	_record_frame(frame, important)
var _last_frame:float = 0
func _record_frame(frame:Replay.Frame, important:bool=false): # I stole this concept from osu
	var should_record = important
	var now = (Time.get_ticks_msec() - start_time) / 1000.0
	if replay.frames.size() > 0 and !important:
		should_record = now - _last_frame >= 1.0 / record_rate
	if !should_record: return false
	_last_frame = now
	frame.time = game.sync_manager.real_time
	replay.frames.append(frame)
	return true
