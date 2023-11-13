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
		Mode.RECORD:
			game.player.hit_state_changed.connect(record_hit_frame)
			game.player.skipped.connect(record_sync_frame)
			game.sync_manager.started.connect(record_sync_frame)
			game.sync_manager.started_audio.connect(record_sync_frame)
			replay.mapset_id = game.mapset.id
			replay.map_id = game.map.id
			replay.mods = game.mods
			replay.write_settings(game.settings)
			replay.score = game.player.score
			if Globals.debug: print("Recording new replay")
		Mode.PLAY:
			var controller = game.player.controller
			controller.queue_frames(replay.frames)
			if Globals.debug: print("Playing replay")
func stop():
	if !active: return
	active = false
	if Globals.debug: print("Stopping replay")
	match mode:
		Mode.RECORD:
			replay.write_to_file("user://recent.rhyr")
		Mode.PLAY:
			pass

func _process(_delta):
	if !active: return
	match mode:
		Mode.RECORD: record_frame()
		Mode.PLAY:
			var controller = game.player.controller
			var now = (Time.get_ticks_msec() - start_time) / 1000.0#game.sync_manager.real_time
			controller.replay_time = now

func record_sync_frame():
	var frame = Replay.SyncFrame.new()
	frame.sync_time = game.sync_manager.current_time
	_record_frame(frame, true)
	record_frame(true)
func record_hit_frame(object_index:int, hit_state:HitObject.HitState):
	var frame = Replay.HitStateFrame.new()
	frame.object_index = object_index
	frame.hit_state = hit_state
	record_frame(true)
	_record_frame(frame, true)
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
		var rotation = game.player.camera.rotation
		frame.rotation = rotation
		frame.position = game.player.camera.position
	_record_frame(frame, important)
var _last_frame:float = 0
func _record_frame(frame:Replay.Frame, important:bool=false): # I stole this concept from osu
	var should_record = true
	var now = (Time.get_ticks_msec() - start_time) / 1000.0
	if replay.frames.size() > 0 and !important:
		should_record = now - _last_frame >= 1.0 / record_rate
	if !should_record: return false
	_last_frame = now
	frame.time = now #game.sync_manager.real_time
	replay.frames.append(frame)
	return true
