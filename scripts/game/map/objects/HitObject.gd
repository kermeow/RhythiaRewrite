extends GameObject
class_name HitObject

signal on_hit_state_changed

enum HitState {
	NONE,
	HIT,
	MISS
}

static var hit_sound:AudioStreamPlayer
static var miss_sound:AudioStreamPlayer

var hit_index:int = 0
var hittable:bool = true
var can_hit:bool = false
var hit_state:int = HitState.NONE:
	get: return hit_state
	set(value):
		hit_state = value
		on_hit_state_changed.emit(value)
		visible = hit_state == HitState.NONE
		self.force_despawn = hit_state != HitState.NONE

func hit():
	if hit_state != HitState.NONE: return
	self.hit_state = HitState.HIT
	visible = false
	if hit_sound: hit_sound.play()
func miss():
	if hit_state != HitState.NONE: return
	self.hit_state = HitState.MISS
	visible = false
	if miss_sound: miss_sound.play()

func get_visibility(_current_time:float):
	return hit_state == HitState.NONE
