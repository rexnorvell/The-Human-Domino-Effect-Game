extends Control

signal pressed

######## WARNING ###########
# Back_Button MUST!!!!! be a child of a parent with an animation
# called "start".
#
# Back_Button should preferably be the child of the main ui scene.

func _on_Back_Button_pressed() -> void:
	SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
	pressed.emit()
	get_tree().change_scene_to_file(gamestate.prev_scene)
