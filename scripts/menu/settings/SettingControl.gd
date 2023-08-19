extends Control
class_name SettingControl

signal value_changed

var signal_emitter
var signal_name:String
var property_name:String

@export var label:String = ""
@export var target:Array[String] = []
var target_setting:Setting
@export var disable_revert:bool = false

@export_subgroup("Requirements")
@export var has_requirement:bool = false
@export var requirement_target:Array[String] = []
var requirement_setting:Setting
@export var required_value:String
@export var requirement_reversed:bool = false
@export var hide_if_unfulfilled:bool = false

@export_subgroup("Modifiers")
@export var multiplier:float = 1.0

func configure():
	pass

func _ready():
	configure()
	$Label.text = label
	
	# Target setting
	assert(target.size() > 0)
	var find_setting = Rhythia.settings
	for child in target:
		find_setting = find_setting.get_setting(child)
	target_setting = find_setting
	reset()
	signal_emitter.connect(signal_name,signal_received)
	value_changed.emit(get_setting())
	target_setting.changed.connect(save_setting)
	$Container/Revert.pressed.connect(revert)
	$Container/Revert.visible = target_setting.value != target_setting.default
	
	# Required setting
	if has_requirement:
		assert(requirement_target.size() > 0)
		find_setting = Rhythia.settings
		for child in requirement_target:
			find_setting = find_setting.get_setting(child)
		requirement_setting = find_setting
		requirement_setting.changed.connect(requirement_changed)
		requirement_changed(requirement_setting.value)

func requirement_changed(value):
	var fulfilled = str(value) == required_value
	if requirement_reversed: fulfilled = !fulfilled
	signal_emitter.set("disabled", !fulfilled)
	signal_emitter.set("editable", fulfilled)
	if hide_if_unfulfilled: visible = fulfilled

func revert():
	target_setting.value = target_setting.default
	$Container/Revert.visible = false
func reset(value=get_setting()):
	signal_emitter.set(property_name,value)
func signal_received(value):
	set_setting(value)
	$Container/Revert.visible = target_setting.value != target_setting.default

func get_setting():
	if target_setting.value is float:
		return target_setting.value * multiplier
	if target_setting.value is int:
		return int(target_setting.value * multiplier)
	return target_setting.value
func set_setting(value):
	if target_setting.value is float:
		value /= multiplier
	if target_setting.value is int:
		value = int(value/multiplier)
	target_setting.value = value
	value_changed.emit(get_setting())

func save_setting(value):
	reset()
	Rhythia.call_deferred("save_settings")
