extends Control
class_name SettingControl

signal value_changed

@export var target:Array[String]

@export_subgroup("Signal")
@export var signal_emitter_path:NodePath
@onready var signal_emitter = get_node(signal_emitter_path)
@export var signal_name:String
@export var property_name:String

@export_subgroup("Modifiers")
@export var multiplier:float = 1.0

var setting:Setting

func _ready():
	assert(target.size() > 0)
	var find_setting = SoundSpacePlus.settings
	for child in target:
		find_setting = find_setting.get_setting(child)
	setting = find_setting

	reset()
	signal_emitter.connect(signal_name,signal_received)

	value_changed.emit(get_setting())
	setting.changed.connect(save_setting)

func reset(value=get_setting()):
	signal_emitter.set(property_name,value)

func signal_received(_value):
	set_setting(_value)

func get_setting():
	if setting.value is float:
		return setting.value * multiplier
	if setting.value is int:
		return int(setting.value * multiplier)
	return setting.value
func set_setting(value):
	if setting.value is float:
		value /= multiplier
	if setting.value is int:
		value = int(value/multiplier)
	setting.value = value
	value_changed.emit(get_setting())

func save_setting(_value):
	SoundSpacePlus.call_deferred("save_settings")
