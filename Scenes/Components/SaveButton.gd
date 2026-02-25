extends TextureButton

#Variables containing necessary Data to process some save data before sending it to the manager
var Save = SaveManager.Save
var Root
var Manager

# Called when the node enters the scene tree for the first time.
func _ready():
	Root = get_tree().get_root()
	Manager = Root.get_node("Manager")
	SaveManager.Save["0"].Current_Level = Manager.current_level.to_string().split(':')[0]
	self.connect("pressed", Callable(SaveManager, "save_button_pressed"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


var green = Color("74cc4c")
var grey = Color("aaaaaa")


func _on_TextureButton_mouse_entered():
	$MarginContainer/Label.set("theme_override_colors/font_color", green)


func _on_TextureButton_mouse_exited():
	$MarginContainer/Label.set("theme_override_colors/font_color", grey)
