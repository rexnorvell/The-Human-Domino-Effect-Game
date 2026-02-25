extends Control

######## WARNING ###########
# Back_Button MUST!!!!! be a child of a parent with an animation
# called "start".
#
# Back_Button should preferably be the child of the main ui scene.

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_TextureButton_mouse_entered():
	# Change label outline color to reddish
	$Button/MarginContainer/Label.add_theme_color_override("font_outline_color", Color(1, 0, 0, 1))

func _on_TextureButton_mouse_exited():
	# Change label outline back to default
	pass

func _on_TextureButton_pressed():
	SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
	get_tree().change_scene_to_file(gamestate.prev_scene)
