extends Button

var up_icon = preload("res://assets/images/ui/arrow_up_white.png")
var dn_icon = preload("res://assets/images/ui/arrow_down_white.png")

func _ready():
	$Label.text = text
	_toggled(button_pressed)

func _toggled(button_pressed):
	icon = up_icon if button_pressed else dn_icon
