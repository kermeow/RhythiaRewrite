extends Node
class_name StatisticsReporter

const REPORT_INTERVAL = 100

@onready var game:GameScene = get_parent()
@onready var statistics:Statistics = Statistics.new()

var last_report:int = 0
var reporting:bool = false

func start():
	reporting = true
	last_report = Time.get_ticks_msec()

func _process(_delta):
	if !reporting: return
	var now = Time.get_ticks_msec()
	if now - last_report >= REPORT_INTERVAL:
		report()
		last_report += REPORT_INTERVAL

func report():
	var frame = statistics.add_frame(game.sync_manager.current_time)
	frame.health = game.player.health / 5.0
	var accuracy = 1.0
	if game.player.score.total > 0:
		accuracy = float(game.player.score.hits) / float(game.player.score.total)
	frame.accuracy = accuracy

func stop():
	reporting = false
