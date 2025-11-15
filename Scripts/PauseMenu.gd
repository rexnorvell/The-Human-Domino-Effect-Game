extends Control

#added in Fall 2024

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#open and close pause menu using the escape button
func _unhandled_input(event):
	if event.is_action_pressed("Pause"):
		visible = !visible
		get_tree().paused = !get_tree().paused

#closes the pause menu
func _on_ResumeBtn_pressed():
	get_tree().paused = false
	visible = false

#returns to main menu
func _on_MainBtn_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/GAME_START.tscn")
	

#quits to desktop, will need to add a save function here when save data is added
func _on_QuitBtn_pressed():
	get_tree().quit()
