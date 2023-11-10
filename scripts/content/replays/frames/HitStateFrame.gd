extends Replay.Frame

var hit_state:HitObject.HitState
var object_index:int
func _encode():
	var bytes = PackedByteArray()
	bytes.resize(5)
	bytes.encode_u32(0, object_index)
	bytes[4] = hit_state
	return bytes
func _decode(bytes:PackedByteArray):
	object_index = bytes.decode_u32(0)
	hit_state = bytes[4]
