extends Node
class_name PlayerController

const SoloController = preload("SoloPlayerController.gd")
const ReplayController = preload("ReplayPlayerController.gd")

var game:GameScene
var player:PlayerObject

signal skip_request
signal move_cursor
signal move_cursor_raw
signal move_camera_raw

func ready():
	game = player.game

func input(_event:InputEvent):
	pass
func process_hitobject(_object:HitObject):
	pass
