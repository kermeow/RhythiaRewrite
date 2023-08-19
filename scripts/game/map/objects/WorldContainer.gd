extends GameObject
class_name WorldContainerObject

signal game_event

var world_node:Node3D

func load_world(world:EnvironmentPlus):
	world_node = world.load_world()
	world_node.set_meta("game", game)
	world_node.set_meta("container", self)
	world_node.set_meta("lighting", !game.settings.skin.background.static_light)
	if game.settings.skin.background.full_static:
		world_node.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(world_node)
