extends Control
class_name ResultsScreen

var screenshot:Texture
var mapset:Mapset
var map_index:int
var score:Score
var mods:Mods
var statistics:Statistics
var settings:GameSettings

func _ready():
	$Background.texture = screenshot
	
	%Container/Restart.pressed.connect(restart)
	%Container/Return.pressed.connect(return_to_menu)
	
	call_deferred("fade_in")

func restart():
	var game_scene = SoundSpacePlus.load_game_scene(SoundSpacePlus.GameType.SOLO,mapset,map_index)
	get_tree().change_scene_to_node(game_scene)
func return_to_menu():
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func fade_in():
	$Background/Blur.color = Color(1.0, 1.0, 1.0, 0.0)
	$Background/Darken.color = Color(0.0, 0.0, 0.0, 0.0)
	var tween = create_tween().set_parallel(true)
	(tween
		.tween_property($Background/Blur,"color:a",1.0,0.4)
		.set_ease(Tween.EASE_IN_OUT)
		.set_trans(Tween.TRANS_CUBIC))
	(tween
		.tween_property($Background/Darken,"color:a",0.4,0.4)
		.set_ease(Tween.EASE_IN_OUT)
		.set_trans(Tween.TRANS_CUBIC)
		.set_delay(0.1))
	tween.play()
