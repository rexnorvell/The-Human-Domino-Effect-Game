extends Node

var sfx_file

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func playSFX(sfx_ref):
	sfx_file = load(sfx_ref)
	$SFX.stream = sfx_file
	$SFX.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
