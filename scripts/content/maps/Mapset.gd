extends ResourcePlus
class_name Mapset

const SIGNATURE:PackedByteArray = [0x72, 0x68, 0x79, 0x74, 0x68, 0x69, 0x61, 0x4d] # rhythiaM
const OLD_SIGNATURE:PackedByteArray = [0x53, 0x53, 0x2b, 0x6d]

var format:int

var song:String

var file_offsets:Dictionary = {
	audio = 0,
	cover = 0
}

var cover:Texture:
	get:
		if format != 3 or cover != null: return cover
		var file = FileAccess.open(path, FileAccess.READ)
		var image = _cover_from_file(file)
		file.close()
		cover = ImageTexture.create_from_image(image)
		return cover
var audio:AudioStream:
	get:
		if format != 3 or audio != null: return audio
		var file = FileAccess.open(path, FileAccess.READ)
		audio = _audio_from_file(file)
		file.close()
		audio.call_deferred("unreference")
		return audio
var length:float:
	get:
		if length: return length
		if self.audio:
			length = self.audio.get_length()
			return length
		return 0

var maps:Array
func get_index_by_id(map_id:String):
	for i in maps.size():
		if maps[i].id == map_id: return i

# Writing files
func write_to_file(path:String): # Write mapset to a path
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(SIGNATURE)
	# Metadata
	if online_id != null:
		var online_id_buffer = online_id.to_ascii_buffer() # Online ID
		file.store_8(online_id_buffer.size())
		file.store_buffer(online_id_buffer)
	else:
		file.store_8(0)
	var name_buffer = name.to_utf16_buffer() # Map name
	file.store_16(name_buffer.size())
	file.store_buffer(name_buffer)
	var creator_buffer = creator.to_utf16_buffer() # Map creator
	file.store_16(creator_buffer.size())
	file.store_buffer(creator_buffer)
	# Audio
	if audio != null:
		var audio_buffer = audio.data
		file.store_64(audio_buffer.size())
		file.store_buffer(audio_buffer)
	else:
		file.store_64(0)
	# Cover
	if cover != null:
		var cover_image = cover.get_image()
		if cover_image.get_format() != Image.FORMAT_RGBA8: cover_image.convert(Image.FORMAT_RGBA8) # Image format will ALWAYS be RGBA8
		var cover_width = min(1024,cover_image.get_width()) # Maximum 1024x1024
		var cover_height = min(1024,cover_image.get_height())
		cover_image.resize(cover_width,cover_height)
		file.store_16(cover_width) # Store width and height before data
		file.store_16(cover_height)
		var cover_buffer = cover_image.get_data() # Store cover data
		file.store_64(cover_buffer.size())
		file.store_buffer(cover_buffer)
	else:
		file.store_16(0)
	file.store_8(maps.size()) # Number of maps in file, assume this is always 1 for now
	for i in range(maps.size()):
		# Store the difficulty's name, then the data
		var map = maps[i]
		var dname_buffer = map.name.to_utf16_buffer()
		file.store_16(dname_buffer.size())
		file.store_buffer(dname_buffer)
		var map_data = JSON.stringify(_serialise_data(map)).to_utf8_buffer()
		file.store_64(map_data.size())
		file.store_buffer(map_data)
	file.close()
# Serialisation
func _serialise_data(map:Map): # Serialise map data to Dictionary
	var data = {}
	data.version = Map.VERSION
	data.notes = []
	for note in map.notes:
		data.notes.append(_serialise_note(map, note))
	return data
func _serialise_note(map:Map, note:Map.Note): # Serialise note to Dictionary
	var data = {
		i=note.index,
		p=[note.x,note.y],
		t=note.time
	}
	if map.version >= 2:
		if note.rotation != 0: data.rotation = note.rotation
	return data

# Reading files
static func read_from_file(path:String,full:bool=false,index:int=0) -> Mapset: # Generate Mapset from file at path
	var file = FileAccess.open(path,FileAccess.READ)
	assert(file != null)
	var set = Mapset.new()
	set.path = path
	if file.get_buffer(4) == OLD_SIGNATURE:
		var file_version = file.get_16()
		match file_version:
			1: set._sspmv1(file,full)
			2: set._sspmv2(file,full)
		if file_version > 2: set.broken = true
		set.format = file_version
		file.close()
		return set
	file.seek(0)
	assert(file.get_buffer(8) == SIGNATURE)
	set.format = 3
	set._rhyt(file,full,index)
	file.close()
	return set
func _rhyt(file:FileAccess,full:bool,index:int=-1): # Load a v3 map
	# Metadata
	var id = FileAccess.get_md5(file.get_path())
	id = id
	var online_id_length = file.get_8() # Online ID
	if online_id_length > 0: online_id = file.get_buffer(online_id_length).get_string_from_ascii()
	var name_length = file.get_16() # Map name
	name = file.get_buffer(name_length).get_string_from_utf16()
	var creator_length = file.get_16() # Map creator
	creator = file.get_buffer(creator_length).get_string_from_utf16()
	# Audio
	file_offsets.audio = file.get_position()
	var audio_length = file.get_64()
	file.seek(file.get_position()+audio_length)
	if audio_length < 1:
		broken = true
	# Cover
	file_offsets.cover = file.get_position()
	var cover_width = file.get_16()
	if cover_width > 0:
		var image = _cover_from_file(file)
		cover = ImageTexture.create_from_image(image)
	# Data
	var indexed = index != -1
	var map_count = file.get_8()
	maps = []
	maps.resize(map_count)
	for i in range(map_count):
		var map = Map.new()
		var dname_length = file.get_16()
		map.name = file.get_buffer(dname_length).get_string_from_utf16()
		var data_length = file.get_64()
		var data = file.get_buffer(data_length).get_string_from_utf8()
		var hash_ctx = HashingContext.new()
		hash_ctx.start(HashingContext.HASH_MD5)
		map.id = hash_ctx.finish().hex_encode()
		if full and (!indexed or index == i):
			_deserialise_data(data,map)
		maps[i] = map
func _sspmv1(file:FileAccess,full:bool): # Load a v1 map
	file.seek(file.get_position()+2) # Header reserved space or something
	var map = Map.new()
	maps = [map]
	id = file.get_line()
	map.id = id
	name = file.get_line()
	song = name
	creator = file.get_line()
	map.creator = creator
	file.seek(file.get_position()+4) # skip last_ms
	var note_count = file.get_32()
	var difficulty = file.get_8()
	map.name = Map.DifficultyNames[difficulty]
	# Cover
	var cover_type = file.get_8()
	match cover_type:
		1:
			var height = file.get_16()
			var width = file.get_16()
			var mipmaps = bool(file.get_8())
			var format = file.get_8()
			var length = file.get_64()
			var image = Image.create_from_data(width,height,mipmaps,format,file.get_buffer(length))
			cover = ImageTexture.create_from_image(image)
		2:
			var image = Image.new()
			var length = file.get_64()
			image.load_png_from_buffer(file.get_buffer(length))
			cover = ImageTexture.create_from_image(image)
		_:
			cover = Map.LegacyCovers.get(difficulty)
	if file.get_8() != 1: # No music
		broken = true
		return
	var music_length = file.get_64()
	var music_buffer = file.get_buffer(music_length)
	var music_format = _get_audio_format(music_buffer)
	if music_format == Globals.AudioFormat.UNKNOWN:
		broken = true
	_audio(music_buffer)
	if not full: return
	for i in range(note_count):
		var note = Map.Note.new()
		note.time = float(file.get_32())/1000
		if file.get_8() == 1:
			note.x = file.get_float()
			note.y = file.get_float()
		else:
			note.x = float(file.get_8())
			note.y = float(file.get_8())
		map.notes.append(note)
	map.notes.sort_custom(func(a,b): return a.time < b.time)
	for i in range(map.notes.size()):
		map.notes[i].index = i
func _sspmv2(file:FileAccess,full:bool): # Load a v2 map
	var map = Map.new()
	maps = [map]
	file.seek(0x26)
	var marker_count = file.get_32()
	var difficulty = file.get_8()
	map.name = Map.DifficultyNames[difficulty]
	file.get_16()
	if !bool(file.get_8()): # Does the map have music?
		map.broken = true
		return
	var cover_exists = bool(file.get_8())
	file.seek(0x40)
	var audio_offset = file.get_64()
	var audio_length = file.get_64()
	var cover_offset = file.get_64()
	var cover_length = file.get_64()
	var marker_def_offset = file.get_64()
	file.seek(0x70)
	var markers_offset = file.get_64()
	file.seek(0x80)
	id = file.get_buffer(file.get_16()).get_string_from_utf8()
	map.id = id
	name = file.get_buffer(file.get_16()).get_string_from_utf8()
	song = file.get_buffer(file.get_16()).get_string_from_utf8()
	creator = ""
	var creators = file.get_16()
	for i in range(creators):
		var new_creator = file.get_buffer(file.get_16()).get_string_from_utf8()
		if i < creators - 1:
			new_creator += ", "
		creator += new_creator
	map.creator = creator
	for i in range(file.get_16()):
		var key_length = file.get_16()
		var key = file.get_buffer(key_length).get_string_from_utf8()
		var value = _read_data_type(file)
		if key == "difficulty_name" and typeof(value) == TYPE_STRING:
			map.name = str(value)
	# Cover
	if cover_exists:
		file.seek(cover_offset)
		var image = Image.new()
		image.load_png_from_buffer(file.get_buffer(cover_length))
		cover = ImageTexture.create_from_image(image)
	else:
		cover = Map.LegacyCovers.get(difficulty)
	# Audio
	file.seek(audio_offset)
	_audio(file.get_buffer(audio_length))
	# Markers
	if not full: return
	file.seek(marker_def_offset)
	var markers = {}
	var types = []
	for _i in range(file.get_8()):
		var type = []
		types.append(type)
		type.append(file.get_buffer(file.get_16()).get_string_from_utf8())
		markers[type[0]] = []
		var count = file.get_8()
		for _o in range(1,count+1):
			type.append(file.get_8())
		file.get_8()
	file.seek(markers_offset)
	for _i in range(marker_count):
		var marker = []
		var ms = file.get_32()
		marker.append(ms)
		var type_id = file.get_8()
		var type = types[type_id]
		for i in range(1,type.size()):
			var data_type = type[i]
			var v = _read_data_type(file,true,false,data_type)
			marker.append_array([data_type,v])
		markers[type[0]].append(marker)
	if !markers.has("ssp_note"):
		map.broken = true
		return
	for note_data in markers.get("ssp_note"):
		if note_data[1] != 7: continue
		var note = Map.Note.new()
		note.time = float(note_data[0])/1000
		note.x = note_data[2].x
		note.y = note_data[2].y
		map.notes.append(note)
	map.notes.sort_custom(func(a,b): return a.time < b.time)
	for i in range(map.notes.size()):
		map.notes[i].index = i
func _read_data_type(file:FileAccess,skip_type:bool=false,skip_array_type:bool=false,type:int=0,array_type:int=0):
	if !skip_type:
		type = file.get_8()
	match type:
		1: return file.get_8()
		2: return file.get_16()
		3: return file.get_32()
		4: return file.get_64()
		5: return file.get_float()
		6: return file.get_real()
		7:
			var value:Vector2
			var t = file.get_8()
			if t == 0:
				value = Vector2(file.get_8(),file.get_8())
				return value
			value = Vector2(file.get_float(),file.get_float())
			return value
		8: return file.get_buffer(file.get_16())
		9: return file.get_buffer(file.get_16()).get_string_from_utf8()
		10: return file.get_buffer(file.get_32())
		11: return file.get_buffer(file.get_32()).get_string_from_utf8()
		12:
			if !skip_array_type:
				array_type = file.get_8()
			var array = []
			array.resize(file.get_16())
			for i in range(array.size()):
				array[i] = _read_data_type(file,true,false,array_type)
			return array
# Cover reading
func _cover_from_file(file:FileAccess): # Intended for v3
	file.seek(file_offsets.cover)
	var cover_width = file.get_16()
	var cover_height = file.get_16()
	var cover_length = file.get_64()
	var cover_buffer = file.get_buffer(cover_length)
	var image = Image.create_from_data(cover_width,cover_height,false,Image.FORMAT_RGBA8,cover_buffer)
	return image
# Audio reading
func _audio_from_file(file:FileAccess): # Intended for v3
	file.seek(file_offsets.audio)
	var audio_length = file.get_64()
	var audio_buffer = file.get_buffer(audio_length)
	var format = _get_audio_format(audio_buffer)
	var stream:AudioStream
	match format:
		Globals.AudioFormat.WAV:
			stream = AudioStreamWAV.new()
			stream.data = audio_buffer
		Globals.AudioFormat.OGG:
			stream = AudioStreamOggVorbis.new()
			stream.packet_sequence = Globals.get_ogg_packet_sequence(audio_buffer)
		Globals.AudioFormat.MP3:
			stream = AudioStreamMP3.new()
			stream.data = audio_buffer
	return stream
func _get_audio_format(buffer:PackedByteArray):
	if buffer.slice(0,4) == PackedByteArray([0x4F,0x67,0x67,0x53]): return Globals.AudioFormat.OGG

	if (buffer.slice(0,4) == PackedByteArray([0x52,0x49,0x46,0x46])
	and buffer.slice(8,12) == PackedByteArray([0x57,0x41,0x56,0x45])): return Globals.AudioFormat.WAV

	if (buffer.slice(0,2) == PackedByteArray([0xFF,0xFB])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xF3])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xFA])
	or buffer.slice(0,2) == PackedByteArray([0xFF,0xF2])
	or buffer.slice(0,3) == PackedByteArray([0x49,0x44,0x33])): return Globals.AudioFormat.MP3

	return Globals.AudioFormat.UNKNOWN
func _audio(buffer:PackedByteArray):
	var format = _get_audio_format(buffer)
	var stream:AudioStream
	match format:
		Globals.AudioFormat.WAV:
			stream = AudioStreamWAV.new()
			stream.data = buffer
		Globals.AudioFormat.OGG:
			stream = AudioStreamOggVorbis.new()
			stream.packet_sequence = AudioStreamOggVorbis.load_from_buffer(buffer)
		Globals.AudioFormat.MP3:
			stream = AudioStreamMP3.new()
			stream.data = buffer
		_:
			print("I don't recognise this format! %s" % buffer.slice(0,3))
			broken = true
	audio = stream
# Deserialisation
func _deserialise_data(data:String,map:Map): # Deserialise Dictionary to map data
	var parsed = JSON.parse_string(data)
	var version = parsed.get("version", 1)
	if version > Map.VERSION:
		map.unsupported = true
	for note_data in parsed.get("notes",[]):
		var note = Map.Note.new()
		note.data = note_data
		note.index = note_data.i
		note.x = note_data.p[0]
		note.y = note_data.p[1]
		note.time = note_data.t
		if version >= 2:
			note.rotation = note_data.get("r", 0)
		map.notes.append(note)
	map.data = parsed
