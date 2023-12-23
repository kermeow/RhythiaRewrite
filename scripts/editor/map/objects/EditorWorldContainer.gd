extends EditorObject
class_name EditorWorldContainerObject

signal editor_event

var world_node:Node3D

func load_world(world:EnvironmentPlus):
	world_node = world.load_world()
	world_node.set_meta("editor", editor)
	world_node.set_meta("container", self)
	world_node.set_meta("lighting", !editor.settings.skin.background.static_light)
	if editor.settings.skin.background.full_static:
		world_node.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(world_node)
