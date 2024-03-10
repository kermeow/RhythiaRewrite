extends SettingControl

@export var enum_names:Array[String] = []

func configure():
	signal_emitter = $Container/OptionButton
	signal_name = "item_selected"
	property_name = "selected"
	
	signal_emitter.clear()
	for name in enum_names:
		signal_emitter.add_item(name)
