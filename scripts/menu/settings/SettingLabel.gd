@tool
extends Label

const DISABLED = true

@onready var parent:SettingControl = get_parent()

func _process(_delta):
	if DISABLED: return
	if !Engine.is_editor_hint(): return
	if !parent: return
	text = parent.label
