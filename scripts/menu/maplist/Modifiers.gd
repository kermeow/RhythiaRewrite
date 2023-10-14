extends Control

func _ready():
	$Reset.pressed.connect(_on_reset_modifiers)

func _on_reset_modifiers():
	pass
