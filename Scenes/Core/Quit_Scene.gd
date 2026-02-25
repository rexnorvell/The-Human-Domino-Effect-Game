extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var parent

# Called when the node enters the scene tree for the first time.
func _ready():
	parent = get_parent() # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_Quit_Button_pressed():
	# Quit to Desktop
	get_tree().quit()

func _on_Cancel_Button_pressed():
	# Go back to Menu Scene
	if parent:
		SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
		parent.loadForegroundScene(ReferenceManager.get_reference("Menu_Scene.tscn"))
