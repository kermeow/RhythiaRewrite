extends Control

func _ready():
	$Reset.pressed.connect(_on_reset_modifiers)
	$Speed/SpeedSpinbox.value_changed.connect(_set_speed)
	$Grid/NofailButton.toggled.connect(_toggle_nofail)
	$SeekButton/SeekSlider.value_changed.connect(_seek_slider_changed)
	
	$Speed/SpeedSpinbox.value = Rhythia.selected_mods.speed_custom
	$Grid/NofailButton.button_pressed = Rhythia.selected_mods.no_fail
	
func get_map_secs():
	var selected_mapset = $"../../..".selected_mapset
	if selected_mapset == null: return -1.0
	return selected_mapset.length as float
	
func sec_to_min_sec(sec: float):
	return "%02d:%02d" % [floor(sec / 60.0), (sec as int % 60)]

func update_seek_slider():
	$SeekButton/SeekSlider.value = (Rhythia.selected_mods.start_from/get_map_secs())*100.0
	print("AAA: ", $SeekButton/SeekSlider.value)
func update_time_label():
	$SeekButton/TimeLabel.text = sec_to_min_sec(Rhythia.selected_mods.start_from)

func _seek_slider_changed(value):
	var secs_in = get_map_secs()/(100.0/value)
	Rhythia.selected_mods.start_from = secs_in
	update_time_label()
	
func _toggle_nofail(pressed):
	Rhythia.selected_mods.no_fail = pressed

func _set_speed(value):
	Rhythia.selected_mods.speed_custom = value

func _on_reset_modifiers():
	pass
