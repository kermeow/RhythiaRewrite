extends Control

signal mapset_selected

@onready var button_container = $Buttons
@onready var origin_button = $Buttons/Button

var page = 0
var max_page = 0

@onready var mapsets = Rhythia.mapsets.items
@onready var listed_mapsets = Rhythia.mapsets.items

var buttons_per_page = 0
var buttons = []

func _ready():
	button_container.remove_child(origin_button)
	button_container.resized.connect(_on_container_resized)
	_on_container_resized(button_container.size)

	$Paginator/First.pressed.connect(_first_paginator)
	$Paginator/Last.pressed.connect(_last_paginator)
	$Paginator/Previous.pressed.connect(_prev_paginator)
	$Paginator/Next.pressed.connect(_next_paginator)

	$Filters/Line/Filters/Search.text_changed.connect(_filter_updated)
	$Filters/Line/Sorts/NameAlphabet.pressed.connect(func():
		_sort_mapsets_name()
		_update_buttons()
	)
	$Filters/Line/Sorts/MapperAlphabet.pressed.connect(func():
		_sort_mapsets_mapper()
		_update_buttons()
	)

func _on_container_resized(size=button_container.size):
	_filter_mapsets()
	_sort_mapsets()
	_calculate_buttons_per_page(size)
	_calculate_pages()
	_create_buttons()
	_update_buttons()
	_update_paginator()

func _filter_mapset(mapset):
	var search = $Filters/Line/Filters/Search.text.strip_edges().to_lower()
	if search.is_empty(): return true
	var search_exact = (
		mapset.name.to_lower().contains(search) or
		mapset.creator.to_lower().contains(search)
	)
#	var search_similarity = maxf(
#		mapset.name.to_lower().similarity(search),
#		mapset.creator.to_lower().similarity(search)
#	) > 0.4
	return search_exact # or search_similarity
func _filter_mapsets():
	listed_mapsets = mapsets.filter(_filter_mapset)
func _sort_mapset_name(a, b):
	var order = a.name.naturalnocasecmp_to(b.name)
	if $Filters/Line/Sorts/NameAlphabet.button_pressed: return order == 1
	return order == -1
func _sort_mapsets_name(): listed_mapsets.sort_custom(_sort_mapset_name)
func _sort_mapset_mapper(a, b):
	var order = a.creator.naturalnocasecmp_to(b.creator)
	if $Filters/Line/Sorts/MapperAlphabet.button_pressed: return order == 1
	return order == -1
func _sort_mapsets_mapper(): listed_mapsets.sort_custom(_sort_mapset_mapper)
func _sort_mapsets():
	_sort_mapsets_mapper()
	_sort_mapsets_name()
func _filter_updated(_value):
	_filter_mapsets()
	_sort_mapsets()
	_calculate_pages()
#	_create_buttons()
	_update_buttons()
	_update_paginator()

func _calculate_buttons_per_page(size):
	var columns = floor(size.x / 500)
	var rows = floor(size.y / 104)
	button_container.columns = columns
	buttons_per_page = columns * rows
func _calculate_pages():
	max_page = ceil(listed_mapsets.size() / buttons_per_page) - 1
	page = mini(page, max_page)

	if page == -1 and max_page != -1: page = 0

func _create_buttons():
	if buttons.size() == buttons_per_page: return
	if buttons.size() > buttons_per_page:
		for i in buttons.size() - buttons_per_page:
			buttons.pop_back().free()
		return
	for i in buttons_per_page - buttons.size():
		var button = origin_button.duplicate()
		button_container.add_child(button)
		buttons.append(button)
		button.pressed.connect(_button_pressed.bind(button))
func _update_button(button, mapset:Mapset):
	button.set_meta("mapset", mapset)
	button.get_node("Cover/Image").texture = mapset.cover
	button.get_node("Title").text = mapset.name
	button.get_node("Mapper").text = mapset.creator
	button.get_node("Length").text = "%s:%02d" % [
		floori(mapset.length/60),
		floori(int(mapset.length)%60)
	]
func _update_buttons():
	var page_offset = page * buttons_per_page
	var visible_mapsets = listed_mapsets.slice(page_offset, page_offset + buttons_per_page)
	for i in buttons.size():
		var button = buttons[i]
		if i >= visible_mapsets.size():
			button.visible = false
			continue
		button.visible = true
		var mapset = visible_mapsets[i]
		_update_button(button, mapset)

func _button_pressed(button):
	mapset_selected.emit(button.get_meta("mapset"))

func _update_paginator():
	$Paginator/Label.text = "Page %s of %s" % [page + 1, max_page + 1]
func _first_paginator():
	page = 0
	_update_buttons()
	_update_paginator()
func _last_paginator():
	page = max_page
	_update_buttons()
	_update_paginator()
func _prev_paginator():
	page = maxi(0, page - 1)
	_update_buttons()
	_update_paginator()
func _next_paginator():
	page = mini(max_page, page + 1)
	_update_buttons()
	_update_paginator()
