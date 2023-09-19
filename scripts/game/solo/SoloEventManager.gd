extends EventManager

var events = []

func prepare(_game:GameScene):
	super.prepare(_game)
	print("hi")
	events = get("eventList")

	for event in events:
		event.data["passed"] = false
		
func _physics_process(delta):
	for event in events:
		if game.sync_manager.current_time >= event.time - game.settings.approach.time / 2:
			if event.type == "AnimateObject":
				if event.has("repeat"):
					for n in event.repeat:
						var objName = event.data.object.split("-")
						var index = int(objName[1]) + n
						var newName = "%s-%s" % ["note", index]
						var game_object = get_parent().get_node("Origin").get_node(newName)
						if game_object == null: return
						game_object.animate(event.data)
				else:
					var game_object = get_parent().get_node("Origin").get_node(event.data.object)
					if game_object == null: return
					game_object.animate(event.data)
