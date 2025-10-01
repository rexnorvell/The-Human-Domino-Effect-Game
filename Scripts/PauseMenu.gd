extends Control

#added in Fall 2024

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#variable to manipulate when game is paused
var is_paused = false: set = set_is_paused

#open and close pause menu using the escape button
func _unhandled_input(event):
	if event.is_action_pressed("Pause"):
		self.is_paused = !is_paused

#pauses the game itself
func set_is_paused(value):
	is_paused = value
	visible = is_paused

#closes the pause menu
func _on_ResumeBtn_pressed():
	self.is_paused = false
	

#returns to main menu
func _on_MainBtn_pressed():
	get_tree().change_scene_to_file("res://Scenes/GAME_START.tscn")
	

#quits to desktop, will need to add a save function here when save data is added
func _on_QuitBtn_pressed():
	get_tree().quit()
