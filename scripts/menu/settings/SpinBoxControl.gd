extends SettingControl

@export_group("SpinBox")
@export var prefix:String = ""
@export var suffix:String = ""
@export var arrow_step:float = 1
@export var step:float = 0
@export var min_value:float = 0
@export var max_value:float = 100
@export var allow_greater:bool = false
@export var allow_lesser:bool = false

func configure():
	signal_emitter = $Container/SpinBox
	signal_name = "value_changed"
	property_name = "value"

	signal_emitter.prefix = prefix
	signal_emitter.suffix = suffix
	signal_emitter.custom_arrow_step = arrow_step
	signal_emitter.step = step
	signal_emitter.min_value = min_value
	signal_emitter.max_value = max_value
	signal_emitter.allow_greater = allow_greater
	signal_emitter.allow_lesser = allow_lesser
