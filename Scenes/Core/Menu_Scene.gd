extends Control

# Declare member variables
var parent

# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent()


func change_scene_with_animation(target_scene, next: bool):
	
	# Play transition
	if next:
		$Menu_Container/AnimationPlayer.play("next")
	else:
		$Menu_Container/AnimationPlayer.play("previous")

	# Wait for transition to finish.
	await $Menu_Container/AnimationPlayer.animation_finished
	
	# Change scene to 'target_scene'
	if parent:
		parent.loadForegroundScene(target_scene)

# Load Quit Scene on Quit Button Pressed
func _on_Quit_Button_pressed():
	SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
	change_scene_with_animation(ReferenceManager.get_reference("Quit_Scene.tscn"), false)

# Load Lobby Scene on Play Button pressed
func _on_Play_Button_pressed():
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	change_scene_with_animation(ReferenceManager.get_reference("Lobby.tscn"), true)

# Load Tutorial Scene on Tutorial Button Pressed
func _on_Tutorial_Button_pressed():
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	change_scene_with_animation(ReferenceManager.get_reference("Tutorial.tscn"), true)
