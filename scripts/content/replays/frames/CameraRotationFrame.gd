extends Replay.Frame

var rotation:Vector2
var position:Vector3
func _encode() -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(10)
	var yaw_packed = floori(rotation.y * 65535.0/360.0)
	var pitch_packed = floori(rotation.x * 65535.0/360.0)
	bytes.encode_u16(0, yaw_packed)
	bytes.encode_u16(2, pitch_packed)
	var x_packed = roundi(position.x * 32767.0/128.0)
	var y_packed = roundi(position.y * 32767.0/128.0)
	var z_packed = roundi(position.z * 32767.0/128.0)
	bytes.encode_s16(4, x_packed)
	bytes.encode_s16(6, y_packed)
	bytes.encode_s16(8, z_packed)
	return bytes
func _decode(bytes:PackedByteArray):
	var yaw = bytes.decode_u16(0) * 360.0/65535.0
	var pitch = bytes.decode_u16(2) * 360.0/65535.0
	rotation = Vector2(pitch, yaw)
	var x = bytes.decode_s16(4) * 3.0/32767.0
	var y = bytes.decode_s16(6) * 3.0/32767.0
	var z = bytes.decode_s16(8) * 3.0/32767.0
	position = Vector3(x, y, z)
