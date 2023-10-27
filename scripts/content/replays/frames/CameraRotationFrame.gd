extends Replay.Frame

var rotation:Vector2
func _encode() -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(4)
	var yaw_packed = floori(rotation.y * 65535.0/360.0)
	var pitch_packed = floori(rotation.x * 65535.0/360.0)
	bytes.encode_u16(0, yaw_packed)
	bytes.encode_u16(2, pitch_packed)
	return bytes
func _decode(bytes:PackedByteArray):
	var yaw = bytes.decode_u16(0) * 360.0/65535.0
	var pitch = bytes.decode_u16(2) * 360.0/65535.0
	rotation = Vector2(pitch, yaw)
