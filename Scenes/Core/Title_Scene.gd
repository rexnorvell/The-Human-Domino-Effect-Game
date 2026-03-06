extends Control

var input_flag: bool = false


func _ready():
	MusicController.playMusic(ReferenceManager.get_reference("quantum.ogg"))


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			handle_change_to_menu_scene()
	elif event is InputEventKey:
		handle_change_to_menu_scene()
	elif event is InputEventScreenTouch:
		handle_change_to_menu_scene()


func handle_change_to_menu_scene():
	if input_flag:
		return
	var parent = get_parent()
	input_flag = true
	gamestate.title_screen_click_flag = true
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	$CenterContainer/AnimationPlayer.play("out")
	await $CenterContainer/AnimationPlayer.animation_finished
	if parent and parent.has_method("loadForegroundScene"):
		parent.loadForegroundScene(ReferenceManager.get_reference("Menu_Scene.tscn"))
