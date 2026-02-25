extends AnimationPlayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

#func _on_CharacterCreation_trigger_animation(anim_name: String):
#	print(anim_name)
#	play(anim_name)# Replace with function body.


func _on_ColorRect_trigger_animation(anim_name: String) -> void:
	play(anim_name)# Replace with function body.
