extends Resource
class_name Mods

var speed_enabled:bool = false
var _speed_up:bool = true
var _speed_amount:float = 1.0
var speed:float:
	get:
		if !speed_enabled: return 1.0
		if _speed_up: return _speed_amount
		else: return 1/_speed_amount

var no_fail:bool = false
var seek:float = 0

var score_multiplier:float = 1

func _init(_data:PackedByteArray=[]):
	if !_data.is_empty(): _decode(_data)

var data:PackedByteArray:
	get = _encode,
	set = _decode

func _encode() -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(18)

	var flags = 0
	if no_fail: flags |= 1 << 0
	if speed_enabled: flags |= 1 << 1
	bytes.encode_s16(0, flags)

	var speed_down_bit = 1 << 7 if !_speed_up else 0
	bytes.encode_double(2, _speed_amount)
	bytes[2] = bytes[2] | speed_down_bit

	bytes.encode_double(10, seek)

	return bytes
func _decode(bytes:PackedByteArray):
	var bytes2 = PackedByteArray(bytes) # FOR DATA MANIPULATION WITHOUT AFFECTING THE ORIGINAL

	var flags = bytes[0] | bytes[1]
	no_fail = flags & 1 << 0
	speed_enabled = flags & 1 << 1

	var speed_down_bit = 1 << 7
	_speed_up = bytes[2] & speed_down_bit == 0
	bytes2[2] = bytes[2] & ~speed_down_bit
	_speed_amount = bytes2.decode_double(2)

	seek = bytes.decode_double(10)
