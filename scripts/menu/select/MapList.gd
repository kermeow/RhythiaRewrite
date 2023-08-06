extends Control
class_name MapList

signal on_mapset_selected
var selected_mapset:Mapset

@export var playlists:PlaylistList

@onready var list:ScrollContainer = $Maps/List
@onready var list_contents:VBoxContainer = $Maps/List/Contents
@onready var top_separator:HSeparator = $Maps/List/Contents/TopSeparator
@onready var btm_separator:HSeparator = $Maps/List/Contents/BottomSeparator
@onready var origin_button:Button = $Maps/List/Contents/Mapset

@onready var origin_list:Array = Rhythia.mapsets.items
var listed_items:Array

var buttons = {}

func _ready():
	origin_button.visible = false
	call_deferred("update_full")
	playlists.on_playlist_selected.connect(playlist_selected)
	$Filters/Search.text_changed.connect(search_updated)
	if Rhythia.selected_mapset:
		if Globals.debug: print("map already selected: ",Rhythia.selected_mapset)
		call_deferred("select_mapset_id",Rhythia.selected_mapset)

func select_mapset_id(id:String):
	update_items()
	var mapset = Rhythia.mapsets.get_by_id(id)
	assert(mapset)
	var index = listed_items.find(mapset)
	print(index)
	selected_mapset = mapset
	on_mapset_selected.emit(mapset)
	list.call_deferred("set","scroll_vertical",max(index * 88 - 8,0))

func playlist_selected(playlist:Playlist=null,all:bool=false):
	if all or !playlist:
		origin_list = Rhythia.mapsets.items
	else:
		playlist.load_mapsets()
		origin_list = playlist.mapsets
	list.scroll_vertical = 0
	call_deferred("update_items")
	call_deferred("update_list")

var _last_scroll:int = 0
func _process(_delta):
	if list.scroll_vertical != _last_scroll:
		_last_scroll = list.scroll_vertical
		update_list()
func _notification(what):
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		call_deferred("update_list")

func search_updated(_text:String):
	call_deferred("update_full")
func update_full():
	update_items()
	update_list()

func update_items():
	listed_items = origin_list.filter(filter_maps)
	listed_items.sort_custom(sort_maps)
func filter_maps(set:Mapset):
	var search = $Filters/Search.text.to_lower()
	if search == "": return true
	return (
		set.name.to_lower().contains(search) or
		set.creator.to_lower().contains(search) or
		set.name.similarity(search) > 0.4 or
		set.creator.similarity(search) > 0.4
	)
func sort_maps(a:Mapset,b:Mapset):
	return a.name.naturalnocasecmp_to(b.name) < 0

func update_list():
	var offset = max(0,floori(list.scroll_vertical/88.0))
	var no_items = ceili(list.size.y/88.0) + 1
	var end = min(listed_items.size(),offset+no_items)
	var visible_items = listed_items.slice(offset,end)
	top_separator.add_theme_constant_override("separation",(offset*88)-4)
	btm_separator.add_theme_constant_override("separation",((listed_items.size()-end)*88.0)-4)
	var buttons_keys = buttons.keys()
	var buttons_values = buttons.values()
	for i in range(buttons_values.size()):
		var button = buttons_values[i]
		if visible_items.has(button.mapset):
			continue
		button.queue_free()
		buttons.erase(buttons_keys[i])
	var i = 0
	for mapset in visible_items:
		i += 1
		mapset = mapset as Mapset
		if buttons.keys().has(mapset):
			list_contents.move_child(buttons[mapset],i)
			continue
		var button = origin_button.duplicate()
		button.connect("pressed",Callable(self,"mapset_button_pressed").bind(button))
		button.visible = true
		button.mapset = mapset
		button.update(selected_mapset == mapset)
		list_contents.add_child(button)
		list_contents.move_child(button,i)
		buttons[mapset] = button

func mapset_button_pressed(button:MapsetButton):
	if selected_mapset == button.mapset: return
	selected_mapset = button.mapset
	on_mapset_selected.emit(selected_mapset)
	if Multiplayer.check_connected() and Multiplayer.check_host():
		Multiplayer.lobby.map_id = selected_mapset.id
	for btn in buttons.values():
		if btn == button: continue
		btn.update()
