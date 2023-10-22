extends Control

func _ready():
	$Reset.pressed.connect(_on_reset_modifiers)
	$Speed/SpeedSpinbox.value_changed.connect(_set_speed)
	$Grid/NofailButton.toggled.connect(_toggle_nofail)
	
	$Grid/NofailButton.button_pressed = Rhythia.selected_mods.no_fail
	
func _toggle_nofail(pressed):
	Rhythia.selected_mods.no_fail = pressed
func _set_speed(value):
	Rhythia.selected_mods.speed_custom = value

func _on_reset_modifiers():
	pass
