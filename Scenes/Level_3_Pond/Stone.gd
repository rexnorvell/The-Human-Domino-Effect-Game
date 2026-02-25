# node for stone in venn diagram scene

extends Area2D

# have stone follow mouse
func _physics_process(delta):
	global_position = get_global_mouse_position()
