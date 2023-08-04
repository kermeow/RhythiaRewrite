extends SettingControl

func configure():
	signal_emitter = $Container/CheckBox
	signal_name = "toggled"
	property_name = "button_pressed"
