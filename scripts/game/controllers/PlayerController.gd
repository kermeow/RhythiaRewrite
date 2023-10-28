extends Node
class_name PlayerController

const Solo = preload("SoloPlayerController.gd")

var game:GameScene
var player:PlayerObject

signal skip_request
signal move_cursor

func ready():
	game = player.game
