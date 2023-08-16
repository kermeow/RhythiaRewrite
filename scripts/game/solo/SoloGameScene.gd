extends GameScene

@export var hud_manager:HUDManager
@export var reporter:StatisticsReporter

@export var world_parent:Node3D

func setup_managers():
	super.setup_managers()
	hud_manager.prepare(self)

func ready():
	var world = Rhythia.worlds.items.front()
	var selected_world = settings.skin.background.world
	var ids = Rhythia.worlds.get_ids()
	if ids.has(selected_world):
		world = Rhythia.worlds.get_by_id(selected_world)
	if world != null:
		var world_node = world.load_world()
		world_node.set_meta("game",self)
		world_parent.add_child(world_node)

	HitObject.hit_sound = $Hit
	HitObject.miss_sound = $Miss

	player.connect("failed",finish.bind(true))

	sync_manager.call_deferred("start",mods.start_from - (settings.approach.time+1.5) * sync_manager.playback_speed)
#	reporter.start()

var ended:bool = false
func finish(failed:bool=false):
	if ended: return
	ended = true
#	reporter.stop()
	$PauseMenu.process_mode = Node.PROCESS_MODE_DISABLED
	$PauseMenu.visible = false
	if Globals.debug: print("failed: %s" % failed)
	if failed:
		if Globals.debug: print("fail animation")
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sync_manager,"playback_speed",0,2)
		tween.play()
		await tween.finished
	else:
		if Globals.debug: print("pass")
		await get_tree().create_timer(0.5).timeout
	var packed_results:PackedScene = preload("res://scenes/Results.tscn")
	var results:ResultsScreen = packed_results.instantiate()
	var image = get_viewport().get_texture().get_image() # hacky screenshot
	results.screenshot = ImageTexture.create_from_image(image)
	results.mapset = mapset
	results.map_index = map_index
	results.score = player.score
	results.mods = mods
#	results.statistics = reporter.statistics
	results.settings = settings
	get_tree().change_scene_to_node(results)
