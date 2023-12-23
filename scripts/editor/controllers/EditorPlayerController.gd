extends Node
class_name EditorPlayerController

const SoloController = preload("EditorSoloPlayerController.gd")
const ReplayController = preload("EditorReplayPlayerController.gd")

var editor:EditorScene
var player:EditorPlayerObject

signal skip_request
signal move_cursor
signal move_cursor_raw
signal move_camera_raw

func ready():
	editor = player.editor

func input(_event:InputEvent):
	pass
func process_hitobject(_object:EditorHitObject):
	pass
