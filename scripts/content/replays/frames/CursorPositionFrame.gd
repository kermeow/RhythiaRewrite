extends Replay.Frame

var position:Vector2
func _encode() -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(4)
	var x_packed = roundi(position.x * 32767.0/128.0)
	var y_packed = roundi(position.y * 32767.0/128.0)
	bytes.encode_s16(0, x_packed)
	bytes.encode_s16(2, y_packed)
	return bytes
func _decode(bytes:PackedByteArray):
	var x = bytes.decode_s16(0) * 3.0/32767.0
	var y = bytes.decode_s16(2) * 3.0/32767.0
	position = Vector2(x, y)
