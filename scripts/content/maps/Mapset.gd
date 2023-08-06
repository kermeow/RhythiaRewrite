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
