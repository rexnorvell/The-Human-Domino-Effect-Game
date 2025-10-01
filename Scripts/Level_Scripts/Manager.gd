# Manager node responsible for handling level transitions
extends Node2D

# Track the currently active level scene
var current_level = null

# Initialize the first level when the scene tree is ready
func _ready() -> void:
	# Check if the game is in tutorial mode
	if gamestate.get_tutorial_mode():
		# Load the tutorial version of the first level
		current_level = load(ReferenceManager.get_reference(gamestate.first_level + "Tutorial.tscn")).instantiate()
	else:
		# Load the standard version of the first level
		current_level = load(ReferenceManager.get_reference(gamestate.first_level + ".tscn")).instantiate()
	
	# Add the first level to the scene
	add_child(current_level)

# Method to change the current level
func change_level(next_scene):
	# Remove the current level from the scene
	current_level.queue_free()
	
	# Instantiate the new level scene
	current_level = next_scene.instantiate()
	
	# Add the new level to the scene
	add_child(current_level)
