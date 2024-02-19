extends SettingControl

@export_subgroup("Registry")
@export var registry_name:String
@onready var registry:Registry = Rhythia.get(registry_name)
@onready var ids:Array = registry.get_ids()

func configure():
	signal_emitter = $Container/OptionButton
	signal_name = "item_selected"
	property_name = "selected"

func reset(value=get_setting()):
	signal_emitter.clear()
	for idx in range(ids.size()):
		var item = registry.items[idx]
		signal_emitter.add_item(item.name,idx)
		signal_emitter.set_item_tooltip(idx,"By %s" % item.creator)
		signal_emitter.set_item_disabled(idx,item.broken)
	signal_emitter.selected = ids.find(value)

func signal_received(value):
	set_setting(ids[value])
	pass
