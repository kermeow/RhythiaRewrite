extends Control

@onready var button_container = $Connected/List/Buttons
@onready var origin_button = $Connected/List/Buttons/Player

@onready var player_names:Dictionary = Online.SpectatePlayerNames
@onready var player_maps:Dictionary = Online.SpectatePlayerMaps

var buttons = []

func _ready():
	$Watching/Buttons/Stop.pressed.connect(Online.StopSpectating)

	button_container.remove_child(origin_button)

	_create_buttons()
	_update_buttons()

func _process(_delta):
	$Disconnected.visible = !Online.GDConnected
	$Connected.visible = Online.GDConnected and !Online.Watching
	$Watching.visible = Online.Watching
	if Online.GDConnected:
		$Connected/Status.text = "Connected as %s | Players: %s" % [Online.GDUserName, player_names.size()]
		if !Online.Watching:
			if buttons.size() != player_names.size():
				_create_buttons()
			_update_buttons()
		else:
			$Watching/Label.text = "You are watching %s" % player_names.get(Online.get_meta("watching_user"))
			if !Online.HasMap:
				$Watching/Label.text += " but you don't have the map: %s" % Online.MapId

func _create_buttons():
	var length = player_names.size()
	if buttons.size() == length: return
	if buttons.size() > length:
		for i in buttons.size() - length:
			buttons.pop_back().free()
		return
	for i in length - buttons.size():
		var button = origin_button.duplicate()
		button_container.add_child(button)
		buttons.append(button)
		button.pressed.connect(_button_pressed.bind(button))
func _update_button(button, id, name, map):
	button.set_meta("userId", id)
	button.get_node("Username").text = name
	button.get_node("Map").text = map
func _update_buttons():
	for i in buttons.size():
		var button = buttons[i]
		var id = player_names.keys()[i]
		_update_button(button, id, player_names[id], player_maps[id])

func _button_pressed(button):
	var id = button.get_meta("userId")
	Online.set_meta("watching_user", id)
	Online.StartSpectating(id)
