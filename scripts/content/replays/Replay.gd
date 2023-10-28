extends ResourcePlus
class_name Replay

const SIGNATURE:PackedByteArray = [0x72, 0x68, 0x79, 0x74, 0x68, 0x69, 0x61, 0x52] # rhythiaR

var mapset_id:String = "MAPSET_ID"
var map_id:String = "MAP_ID"
var player_name:String = "Player"
var mods:PackedByteArray
var settings:PackedByteArray
var frames:Array[Frame]

func write_settings(_settings:GameSettings):
	settings = PackedByteArray()
	settings.resize(9)
	var flags = 0
	if _settings.camera.lock: flags |= 1 << 0
	if _settings.camera.drift: flags |= 1 << 1
	settings[0] = flags
	settings.encode_half(1, _settings.approach.time)
	settings.encode_half(3, _settings.approach.distance)
	settings.encode_half(5, _settings.camera.fov)
	settings.encode_half(7, _settings.camera.parallax.camera)
func read_settings(_settings:GameSettings):
	var flags = settings[0]
	_settings.camera.lock = flags & 1 << 0
	_settings.camera.drift = flags & 1 << 1
	_settings.approach.time = settings.decode_half(1)
	_settings.approach.distance = settings.decode_half(3)
	_settings.camera.fov = settings.decode_half(5)
	_settings.camera.parallax.camera = settings.decode_half(7)

class Frame:
	var time:float # Time of the frame
	func _encode() -> PackedByteArray: return [] # Convert the frame data to bytes
	func _decode(_bytes:PackedByteArray): pass # Convert bytes to frame data
class UnknownTypeFrame:
	extends Frame
const CameraRotationFrame = preload("frames/CameraRotationFrame.gd")
const CursorPositionFrame = preload("frames/CursorPositionFrame.gd")
const HitStateFrame = preload("frames/HitStateFrame.gd")
const Opcodes = {
	0x01: CameraRotationFrame,
	0x02: CursorPositionFrame,
	0x03: HitStateFrame
}

func get_opcode_for(frame:Frame):
	for opcode in Opcodes:
		var type = Opcodes[opcode]
		if is_instance_of(frame, type): return opcode
	return 0x00

# Writing files
func write_to_file(path:String):
	var file = FileAccess.open(path,FileAccess.WRITE)
	assert(file != null)
	file.store_buffer(SIGNATURE)
#	file.store_line("gullible") # David asked for this
	# Map info
	file.store_pascal_string(mapset_id)
	file.store_pascal_string(map_id)
	# Player info
	var player_name_buffer = player_name.to_utf16_buffer() # Player name
	file.store_16(player_name_buffer.size())
	file.store_buffer(player_name_buffer)
	file.store_buffer(mods)
	file.store_16(settings.size())
	file.store_buffer(settings)
	# Frames
	file.store_32(frames.size()) # Frame count
	for frame in frames:
		file.store_8(get_opcode_for(frame) or 0x00)
		file.store_float(frame.time)
		var data = frame._encode()
		file.store_8(data.size())
		if data.size() > 0: file.store_buffer(data)
# Reading files
static func read_from_file(path:String) -> Replay: # Generate Replay from file at path
	var file = FileAccess.open(path,FileAccess.READ)
	assert(file != null)
	assert(file.get_buffer(8) == SIGNATURE)
#	file.get_line()
	var replay = Replay.new()
	# Map info
	replay.mapset_id = file.get_pascal_string()
	replay.map_id = file.get_pascal_string()
	# Player info
	var player_name_length = file.get_16() # Player name
	replay.player_name = file.get_buffer(player_name_length).get_string_from_utf16()
	replay.mods = file.get_buffer(Mods.DataLength)
	replay.settings = file.get_buffer(file.get_8())
	# Frames
	replay.frames = []
	var frame_count = file.get_32()
	for i in frame_count:
		var opcode = file.get_8()
		var frame:Frame
		var type = Opcodes[opcode]
		if type != null:
			frame = type.new()
		else:
			frame = UnknownTypeFrame.new()
			print("Unknown frame type! Index %s Opcode %2x" % [i, opcode])
		frame.time = file.get_float()
		var data_length = file.get_8()
		if data_length > 0:
			var data = file.get_buffer(data_length)
			frame._decode(data)
		replay.frames.append(frame)
	return replay
