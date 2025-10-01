extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var isInArea = false

#the two below functions are for checking if the player is near the spear
func _on_Spear_body_entered(body):
	isInArea = true
	$Interaction.visible = true

func _on_Spear_body_exited(body):
	isInArea = false
	$Interaction.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	#if the player is in the area and interacts with the object
	if isInArea and Input.is_action_just_pressed("Interact"):
		$testcase.visible = true
	elif !(isInArea):
		$testcase.visible = false
