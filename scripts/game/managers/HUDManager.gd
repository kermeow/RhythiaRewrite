extends GameManager
class_name HUDManager

@export var hud:Node3D

@onready var right:RightHUD = hud.get_node("RightViewport/Control")
@onready var left:LeftHUD = hud.get_node("LeftViewport/Control")
@onready var energy:EnergyHUD = hud.get_node("EnergyViewport/Control")
@onready var timer:TimerHUD = hud.get_node("TimerViewport/Control")

static func comma_sep(n: int):
	var string = str(n)
	var mod = string.length() % 3
	var result = ""
	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod: result += ","
		result += string[i]
	return result

func prepare(_game:GameScene):
	super.prepare(_game)
	right.manager = self
	left.manager = self
	energy.manager = self
	timer.manager = self

func _process(_delta):
	right.score = game.player.score
	left.score = game.player.score
	energy.health = game.player.health
	timer.sync_manager = game.sync_manager
	timer.song_name = "%s [%s]" % [game.mapset.name, game.map.name]
	if game.replay_manager.mode == ReplayManager.Mode.PLAY:
		timer.song_name = "WATCHING %s PLAY %s" % [game.replay.player_name, timer.song_name]
	timer.skippable = game.check_skippable()
