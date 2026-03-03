extends Control

# Declare member variables
var parent

# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent() # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func change_scene_with_animation(target_scene):
	# Play transition
	$Menu_Container/AnimationPlayer.play("transition_out")

	# Wait for transition to finish.
	await $Menu_Container/AnimationPlayer.animation_finished
	
	# Change scene to 'target_scene'
	if parent:
		parent.loadForegroundScene(target_scene)

# Load Quit Scene on Quit Button Pressed
func _on_Quit_Button_pressed():
	SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
	change_scene_with_animation(ReferenceManager.get_reference("Quit_Scene.tscn"))

# Load Lobby Scene on Play Button pressed
func _on_Play_Button_pressed():
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	change_scene_with_animation(ReferenceManager.get_reference("Lobby.tscn"))

# Load Tutorial Scene on Tutorial Button Pressed
func _on_Tutorial_Button_pressed():
	SFXController.playSFX(ReferenceManager.get_reference("next.wav")) #Play sound
	change_scene_with_animation(ReferenceManager.get_reference("Tutorial.tscn"))
