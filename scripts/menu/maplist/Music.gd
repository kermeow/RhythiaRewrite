extends AudioStreamPlayer

func _ready():
	get_parent().on_mapset_selected.connect(_on_mapset_selected)

func _on_mapset_selected(mapset:Mapset):
	stop()
	stream = mapset.audio
	play(mapset.length / 3.0)
