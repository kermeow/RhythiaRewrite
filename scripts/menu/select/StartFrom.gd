extends Control

var first_map_selected:bool = true

func _ready():
	%MapList.on_mapset_selected.connect(on_mapset_selected)
	$Slider.value_changed.connect(value_changed)

func on_mapset_selected(mapset:Mapset):
	$Slider.max_value = mapset.length
	$Slider.value = 0
	if first_map_selected and mapset.id == SoundSpacePlus.selected_mapset:
		$Slider.value = SoundSpacePlus.selected_mods.start_from
	first_map_selected = false
	call_deferred("update_label")

func value_changed(value):
	SoundSpacePlus.selected_mods.start_from = value
	call_deferred("update_label")

func update_label():
	var total_seconds = int($Slider.value)
	var minutes = floor(total_seconds / 60)
	var seconds = total_seconds % 60
	$Label.text = "Start from %sm %ss" % [minutes,seconds]
	if total_seconds > 2: %MapList/Music.seek(total_seconds)
