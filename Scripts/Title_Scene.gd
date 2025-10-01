extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var input_flag = false

func handleChangeToMenuScene():
	if input_flag == true:
		return
		
	var parent = get_parent()
	
	input_flag = true
	gamestate.title_screen_click_flag = true
	# Play animation
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	$Title_Container/AnimationPlayer.play("Transition")
	await $Title_Container/AnimationPlayer.animation_finished
	
	if parent and parent.has_method("loadForegroundScene"):
		parent.loadForegroundScene(ReferenceManager.get_reference("Menu_Scene.tscn"))
		
# Called when the node enters the scene tree for the first time.
func _ready():
	MusicController.playMusic(ReferenceManager.get_reference("quantum.ogg"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			handleChangeToMenuScene()
	elif event is InputEventKey:
		handleChangeToMenuScene()
	elif event is InputEventScreenTouch:
		handleChangeToMenuScene()
