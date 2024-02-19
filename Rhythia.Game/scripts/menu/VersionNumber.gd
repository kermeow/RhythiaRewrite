extends Control

func _ready():
	$Label.text = "%s [%s]" % [ProjectSettings.get_setting_with_override("application/config/name"),ProjectSettings.get_setting_with_override("application/config/version")]
