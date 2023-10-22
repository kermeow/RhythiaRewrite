extends Control

func _ready():
	$Reset.pressed.connect(_on_reset_modifiers)
	$Speed/SpeedSpinbox.value_changed.connect(_set_speed)
	
func _set_speed(value):
	print("Changed speed to: ", value);
	Rhythia.selected_mods.speed_custom = value

func _on_reset_modifiers():
	pass
