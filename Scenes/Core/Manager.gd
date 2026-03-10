# Manager node responsible for handling level transitions
extends Node2D

# --- Node References ---
@onready var anim_player = $TransitionLayer/AnimationPlayer
@onready var fade_rect = $TransitionLayer/FadeRect

# Track the currently active level scene
var current_level = null

# Initialize the first level when the scene tree is ready
func _ready() -> void:
	# 1. Start Solid Black to hide the "Godot Grey" stutter
	fade_rect.modulate.a = 1.0
	fade_rect.visible = true
	
	# Wait two frames to let everything initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check if the game is in tutorial mode
	var initial_path = "" # Renamed from level_path to avoid conflicts
	if gamestate.get_tutorial_mode():
		initial_path = ReferenceManager.get_reference(gamestate.first_level + "Tutorial.tscn")
	else:
		initial_path = ReferenceManager.get_reference(gamestate.first_level + ".tscn")
		
	current_level = load(initial_path).instantiate()
	add_child(current_level)
	
	# 2. Fade in once the level is actually ready
	anim_player.play_backwards("fade_one_shot")

# Method to change the current level using a Dip-To-Black
func change_level(next_scene_resource):
	# 1. Start the animation from transparent
	fade_rect.modulate.a = 0.0
	fade_rect.visible = true
	anim_player.play("fade_one_shot")
	
	# 2. Wait exactly 0.5s for the screen to be pitch black
	await get_tree().create_timer(0.5).timeout
	
	# --- SWAP THE SCENES IN THE DARK ---
	if current_level:
		current_level.queue_free()
	
	await get_tree().process_frame
	
	current_level = next_scene_resource.instantiate()
	add_child(current_level)
	# -----------------------------------
	
	# 3. Wait for the animation to finish fading out
	await anim_player.animation_finished
	fade_rect.visible = false
