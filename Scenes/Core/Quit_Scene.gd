extends Control


var parent

# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent() # Replace with function body.


# Quit to desktop
func _on_Quit_Button_pressed():
	get_tree().quit()


# Go back to Menu Scene
func _on_Cancel_Button_pressed():
	if parent:
		SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
		parent.loadForegroundScene(ReferenceManager.get_reference("Menu_Scene.tscn"))
