extends Control

signal map_selected

@onready var maplist = $"../Maps"

@onready var difficulty_container = $Sections/Details/Maps
@onready var origin_difficulty = $Sections/Details/Maps/Button

var difficulties = []

var selected_mapset
var selected_map_index = 0

func _ready():
	visible = false

	difficulty_container.remove_child(origin_difficulty)

	maplist.mapset_selected.connect(_mapset_selected)
	$Sections/Details/Play.pressed.connect(_play_pressed)

var tween:Tween
var moving = false
func fade_in():
	if moving: return
	moving = true
	modulate.a = 0
	visible = true
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "modulate:a", 1, 0.2)
	tween.play()
	await tween.finished
	moving = false
func fade_out():
	if moving: return
	moving = true
	modulate.a = 1
	visible = true
	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "modulate:a", 0, 0.2)
	tween.play()
	await tween.finished
	visible = false
	moving = false

func _gui_input(event):
	if event is InputEventMouseButton:
		fade_out()

func _mapset_selected(mapset):
	selected_mapset = mapset
	selected_map_index = mini(selected_map_index, selected_mapset.maps.size() - 1)
	_update_details()
	_create_difficulties()
	_update_difficulties()
	fade_in()

func _update_details():
	$Sections/Details/Cover/Image.texture = selected_mapset.cover
	$Sections/Details/Title.text = selected_mapset.name
	$Sections/Details/Line/Mapper.text = selected_mapset.creator
	$Sections/Details/Line/Length.text = "%s:%02d" % [
		floori(selected_mapset.length/60),
		floori(int(selected_mapset.length)%60)
	]
	$Sections/Extra/Debug.text = "%s - %s" % [
		selected_mapset.id,
		"local" if selected_mapset.local else selected_mapset.online_id
	]

func _create_difficulties():
	if difficulties.size() == selected_mapset.maps.size(): return
	if difficulties.size() > selected_mapset.maps.size():
		for i in difficulties.size() - selected_mapset.maps.size():
			difficulties.pop_back().free()
		return
	for i in selected_mapset.maps.size() - difficulties.size():
		var button = origin_difficulty.duplicate()
		difficulty_container.add_child(button)
		difficulties.append(button)
		button.pressed.connect(_difficulty_pressed.bind(button))
func _update_difficulties():
	for i in selected_mapset.maps.size():
		var map = selected_mapset.maps[i]
		var button = difficulties[i]
		button.set_meta("map_index", i)
		button.text = map.name
		button.get_node("Label").text = map.name
		button.button_pressed = selected_map_index == i

func _difficulty_pressed(button):
	selected_map_index = button.get_meta("map_index")
	map_selected.emit(selected_mapset, selected_map_index)
	_update_difficulties()

func _play_pressed():
	var scene = Rhythia.load_game_scene(Rhythia.GameType.SOLO, selected_mapset, selected_map_index)
	get_tree().change_scene_to_node(scene)
