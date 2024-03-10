extends Resource
class_name Statistics

var frames:Array[Frame] = []
func add_frame(time:float):
	var frame = Frame.new()
	frame.time = time
	frames.append(frame)
	return frame

class Frame:
	var time:float = 0.0
	
	var health:float = 1.0
	var accuracy:float = 1.0
