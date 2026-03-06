extends Control


func _on_Back_Button_pressed() -> void:
	SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
	get_tree().change_scene_to_file(gamestate.prev_scene)
