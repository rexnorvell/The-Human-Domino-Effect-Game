extends Node

var music_file

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func playMusic(music_ref):
	music_file = load(music_ref)
	$Music.stream = music_file
	$Music.play()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
