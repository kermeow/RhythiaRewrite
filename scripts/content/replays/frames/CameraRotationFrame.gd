extends Replay.Frame

var rotation:Vector3
var position:Vector3
func _encode() -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(12)
	var rot_x_packed = floori(rotation.x * 32767.0/PI)
	var rot_y_packed = floori(rotation.y * 32767.0/PI)
	var rot_z_packed = floori(rotation.z * 32767.0/PI)
	bytes.encode_s16(0, rot_x_packed)
	bytes.encode_s16(2, rot_y_packed)
	bytes.encode_s16(4, rot_z_packed)
	var x_packed = roundi(position.x * 32767.0/128.0)
	var y_packed = roundi(position.y * 32767.0/128.0)
	var z_packed = roundi(position.z * 32767.0/128.0)
	bytes.encode_s16(6, x_packed)
	bytes.encode_s16(8, y_packed)
	bytes.encode_s16(10, z_packed)
	return bytes
func _decode(bytes:PackedByteArray):
	var rot_x = bytes.decode_s16(0) * PI/32767.0
	var rot_y = bytes.decode_s16(2) * PI/32767.0
	var rot_z = bytes.decode_s16(4) * PI/32767.0
	rotation = Vector3(
		rot_x,
		rot_y,
		rot_z
	)
	var x = bytes.decode_s16(6) * 128.0/32767.0
	var y = bytes.decode_s16(8) * 128.0/32767.0
	var z = bytes.decode_s16(10) * 128.0/32767.0
	position = Vector3(x, y, z)
