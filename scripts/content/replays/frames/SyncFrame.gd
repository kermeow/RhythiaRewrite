extends Replay.Frame

var sync_time:float

func _encode():
	var data = PackedByteArray()
	data.resize(4)

	data.encode_float(0, sync_time)

	return data
func _decode(data:PackedByteArray):
	sync_time = data.decode_float(0)
