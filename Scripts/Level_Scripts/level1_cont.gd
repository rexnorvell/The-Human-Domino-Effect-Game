# Elcitrap selection scene where players choose their traits
extends Node

# Export scene references and configuration variables
@export var Elcitrap: PackedScene # Prefab for Elcitrap objects
@export var next_scene: PackedScene # Scene to load after selection
@export var trait_queue = [] + curriculum.traits # List of available traits

# Signals for scene animations and progression
signal trigger_animation(anim_name) # Signal to trigger scene animations
signal five_selected() # Signal when 5 traits are selected

# Predefined position grids for Elcitraps
# Positions for red Elcitraps (x, y coordinates)
var red_pos = [[361, 121], [321, 163], [294, 214], [278, 272], [284, 333]]
# Positions for blue Elcitraps (x, y coordinates)
var blue_pos = [[398, 500], [454, 519], [514, 528], [574, 519], [628, 499]]
# Positions for green Elcitraps (x, y coordinates)
var green_pos = [[663, 124], [700, 169], [726, 219], [738, 274], [736, 333]]


# Track selected traits and player readiness
@export var selected = []  # List of selected traits
var players_ready = []  # List of players who have completed selection

# Narration text to guide players through trait selection
var narration_text = ["You can see clearly now the choices before you.",
"Click on these elcitraps to make them part of your identity.",
"You can be whoever you want to be, all you have to do is choose."]

var narration_count = 1 # Current narration text index

# Initialize the scene when it enters the scene tree
func _ready() -> void:
	# Indices to track placement of Elcitraps in each color group
	var r_i = 0 # Red Index
	var b_i = 0 # Blue Index
	var g_i = 0 # Green Index
	
	# Populate Elcitraps on screen
	for i in range(len(trait_queue)):
		# Instantiate a new Elcitrap
		var elcitrap = Elcitrap.instantiate()
		
		# Distribute Elcitraps in a color-coded pattern
		# Red Elcitraps (every 3n trait)
		if i % 3 == 0:
			elcitrap.position = Vector2(red_pos[r_i][0], red_pos[r_i][1])
			r_i += 1
			
		# Blue Elcitraps (every 3n+1 trait)
		elif i % 3 == 1:
			elcitrap.position = Vector2(blue_pos[b_i][0], blue_pos[b_i][1])
			b_i += 1
			
		# Green Elcitraps (every 3n+2 trait)
		elif i % 3 == 2:
			elcitrap.position = Vector2(green_pos[g_i][0], green_pos[g_i][1])
			g_i += 1
		
		# Initialize Elcitrap with trait and position
		elcitrap.init(trait_queue[i], elcitrap.position)
		
		# Add Elcitrap to the scene
		add_child(elcitrap)
	
	# Set initial narration text and start animation
	$Narration.text = narration_text[0]
	$Narration/TextAnimationPlayer.play("Reveal", -1, 2)

# Check for trait selection completion each frame
func _process(delta: float) -> void:
	# Emit signal when 5 traits are selected
	if len(selected) == 5:
		emit_signal("five_selected")

# Handle proceeding to the next scene
func _on_Button_pressed() -> void:
#	print("id", get_tree().get_network_unique_id())
	# Synchronize selected traits across the network
	rpc("set_elcitraps", selected)
#	print("debug: ", gamestate.elcitraps)
	
	# Hide button and narration
	$Button.visible = false
	$Narration.visible = false
	
	# Trigger scene transition animation
	emit_signal("trigger_animation", "Fade")

# Network RPC to set selected Elcitraps for each player
@rpc("any_peer", "call_local") func set_elcitraps(elcitraps):
	gamestate.elcitraps[multiplayer.get_remote_sender_id()] = elcitraps

# Network RPC to start the next scene
@rpc("any_peer") func start_game():
	get_parent().change_level(next_scene)

# Handle narration text progression
func _on_TextAnimationPlayer_animation_finished(anim_name: String) -> void:
	# Cycle through narration text
	if narration_count < len(narration_text):
		$Narration.text = narration_text[narration_count]
		$Narration/TextAnimationPlayer.play("Reveal")
		narration_count += 1

# Handle scene transition animations
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	# Toggle color rect visibility during fade animation
	if (anim_name == "Fade"):
		$ZIndexSetter/ColorRect.visible = !$ZIndexSetter/ColorRect.visible
		emit_signal("trigger_animation", "Screen_Wipe")
	else:
		# Start the game after animations complete
		start_game()
