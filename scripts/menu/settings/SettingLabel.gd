@tool
extends Label

@onready var parent:SettingControl = get_parent()

func _process(_delta):
	if !Engine.is_editor_hint(): return
	text = parent.label
