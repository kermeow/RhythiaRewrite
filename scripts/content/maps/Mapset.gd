extends ResourcePlus
class_name Mapset

const SIGNATURE:PackedByteArray = [0x72, 0x68, 0x79, 0x74, 0x68, 0x69, 0x61, 0x4d]

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
		var image = MapsetReader.cover_from_file(file,self)
		file.close()
		cover = ImageTexture.create_from_image(image)
#		cover.call_deferred("unreference")
		return cover
var audio:AudioStream:
	get:
		if format != 3 or audio != null: return audio
		var file = FileAccess.open(path, FileAccess.READ)
		audio = MapsetReader.audio_from_file(file,self)
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

# Writing files
func write_to_file(path:String): # Write mapset to a path
	var file = FileAccess.open(path,FileAccess.WRITE)
	file.store_buffer(MapsetReader.SIGNATURE)
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
