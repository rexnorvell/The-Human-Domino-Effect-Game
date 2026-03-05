extends Control


var parent

# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()


# Quit to desktop
func _on_Quit_Button_pressed():
	get_tree().quit()


# Go back to Menu Scene
func _on_Cancel_Button_pressed():
	# Play transition
	$MarginContainer/AnimationPlayer.play("out")

	# Wait for transition to finish.
	await $MarginContainer/AnimationPlayer.animation_finished
	
	if parent:
		SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
		parent.loadForegroundScene(ReferenceManager.get_reference("Menu_Scene.tscn"))
