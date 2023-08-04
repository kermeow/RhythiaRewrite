extends SyncManager
class_name AudioSyncManager

@export var audio_player:AudioStreamPlayer

var audio_stream:AudioStream:
	get:
		return audio_stream
	set(value):
		length = value.get_length()
		audio_stream = value
var time_delay:float = 0

func _set_offset():
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	audio_player.seek(real_time + time_delay)
func _start_audio():
	if audio_stream is AudioStreamMP3:
		(audio_stream as AudioStreamMP3).loop = false
	if audio_stream is AudioStreamOggVorbis:
		(audio_stream as AudioStreamOggVorbis).loop = false
	if audio_stream is AudioStreamWAV:
		(audio_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	audio_player.stream = audio_stream
	audio_player.play(real_time)
	_set_offset()

func _process(delta:float):
	super._process(delta)
	if !playing: return
	var should_be_playing = real_time >= 0 and real_time <= length and playback_speed > 0
	if !audio_player.playing and should_be_playing:
		_start_audio()
	if audio_player.playing and !should_be_playing:
		audio_player.stop()
	if playback_speed > 0:
		audio_player.pitch_scale = playback_speed

func seek(from:float=0):
	super.seek(from)
	_set_offset()

func just_paused():
	audio_player.stop()

#func try_finish():
#	if (real_time - time_delay) > length:
#		finish()
