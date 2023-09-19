extends BaseManager
class_name EventManager

var eventList:Array = []
var data:Dictionary = {}

func read_events_json(jsonPath):
	var json = JSON.new()
	var file = FileAccess.open(jsonPath, FileAccess.READ)
	var content = file.get_as_text()
	var err = json.parse(content)
	data = json.data
	return err

func prepare(_game:GameScene):
	super.prepare(_game)
	if (FileAccess.file_exists("user://maps/events/%s.json" % game.map.id)):
		var err = read_events_json("user://maps/events/%s.json" % game.map.id)
		if err == OK:
			for event in data.get("events",[]):
				eventList.append(event)
