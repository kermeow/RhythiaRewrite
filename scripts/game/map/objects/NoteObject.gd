extends HitObject
class_name NoteObject

var note:Map.Note
var spawn_distance:float = 50
var colour:Color
var mixed_colour:Color

func _init(_id:String="",_note:Map.Note=null,_colour:Color=Color.RED):
	super._init(_id)
	self.note = _note
	colour = _colour
	scale = Vector3.ONE*0.865

func _physics_process(_delta):
	var time = note.time-game.sync_manager.current_time
	can_hit = hittable and time <= 0 and hit_state == HitState.NONE

func update(current_time:float):
	var time = (note.time-current_time)/(note.time-spawn_time)
	transform.origin = Vector3(-note.x+1,-note.y+1,time*spawn_distance)
	var fade_in_time = (1 - time) / game.settings.skin.block.fade_in_time
	var fade_out_time = time / game.settings.skin.block.fade_out_time
	var fade_in = min(fade_in_time/game.settings.skin.block.fade_in_amount,1.0)
	var fade_out = min(fade_out_time/game.settings.skin.block.fade_out_amount,1.0)
	if game.settings.skin.block.fade_in_mode != 0: fade_in = 1
	if game.settings.skin.block.fade_out_mode != 0: fade_out = 1
	var opacity = game.settings.skin.block.opacity
	mixed_colour = Color(colour,max(0,opacity*fade_in*fade_out))

func get_visibility(current_time:float):
	if game.settings.skin.block.fade_out_mode == 2:
		return current_time > 0
	return hit_state == HitState.NONE
