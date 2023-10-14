extends Control

@onready var maplist = $"../Maps"

var selected_mapset
var selected_map_index = 0

func _ready():
	visible = false
	maplist.mapset_selected.connect(_mapset_selected)

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
	_update_details()
	fade_in()

func _update_details():
	$Sections/Details/Cover/Image.texture = selected_mapset.cover
	$Sections/Details/Title.text = selected_mapset.name
	$Sections/Details/Line/Mapper.text = selected_mapset.creator
	$Sections/Details/Line/Length.text = "%s:%02d" % [
		floori(selected_mapset.length/60),
		floori(int(selected_mapset.length)%60)
	]
