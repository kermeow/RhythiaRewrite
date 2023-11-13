extends Resource
class_name Score

var failed:bool = false
var failed_at:float = 0

var score:int = 0

var multiplier:int = 1:
	get: return multiplier
	set(value):
		multiplier = clampi(value,1,8)
var sub_multiplier:int = 0:
	get: return sub_multiplier
	set(value):
		sub_multiplier = clampi(value,0,10)

var hits:int = 0
var misses:int = 0
var total:int:
	get:
		return hits + misses
const RankLetters = [
	[1,"SS"],
	[0.98,"S"],
	[0.95,"A"],
	[0.9,"B"],
	[0.85,"C"],
	[0.8,"D"],
	[0.75,"E"],
	[0,"F"]
]
var rank:String:
	get:
		if failed:
			return "F"
		if total > 0:
			for letter in RankLetters:
				if hits >= total * letter[0]:
					return letter[1]
		return "SS"

var combo:int = 0:
	get: return combo
	set(value):
		combo = value
		if combo > max_combo:
			max_combo = combo
var max_combo:int = 0

var submitted:bool = false

func _init(_data:PackedByteArray=[]):
	if !_data.is_empty(): _decode(_data)

var data:PackedByteArray:
	get = _encode,
	set = _decode

func _encode() -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(15)

	var flags = 0
	if failed: flags |= 1 << 0
	bytes[0] = flags

	bytes.encode_half(1, failed_at)
	bytes.encode_u32(3, score)
	bytes.encode_u32(7, hits)
	bytes.encode_u32(11, misses)

	return bytes
func _decode(bytes:PackedByteArray):
	var bytes2 = PackedByteArray(bytes) # FOR DATA MANIPULATION WITHOUT AFFECTING THE ORIGINAL

	var flags = bytes[0]
	failed = flags & 1 << 0

	failed_at = bytes.decode_half(1)
	score = bytes.decode_u32(3)
	hits = bytes.decode_u32(7)
	misses = bytes.decode_u32(11)
