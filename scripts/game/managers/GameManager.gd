extends Node
class_name GameManager

signal preparing

var game:GameScene

func prepare(_game:GameScene):
	game = _game
	call_deferred("emit_signal","preparing",_game)
