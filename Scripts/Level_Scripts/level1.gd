# quantum realm scene where player captures wavy elcitraps
extends Node

# Export scene references and configuration variables
@export var Elcitrap: PackedScene # Prefab for Elcitrap objects
@export var next_scene: PackedScene # Scene to load after this one
@export var total_captured = 0 # Track total number of Elcitraps captured

# Initialize trait queue with traits from curriculum
@export var trait_queue = [] + curriculum.traits

# Track players who are ready to proceed
var players_ready = []

# Dialogue text to be displayed during the scene
var dialogue = ["You now have the power to shape your future.",
"Now, use your Oauabae to help you see through the chaos!"]

# Current dialogue page index
var page = 0

# Cache references to UI and timer nodes for dialogue effect
@onready var dialogue_label = $DialogueBox/DialogueText  # Assumes dialogue is a RichTextLabel node
@onready var timer = $DialogueBox/Timer  # Assumes there's a Timer node for text animation

# Initialize the scene when it enters the scene tree
func _ready():
	# Add position data to each trait in the queue
	for i in range(15):
		trait_queue[i].append([i*60 + 100, 550])
	
	# Seed random number generator
	randomize()
	# Start the game sequence
	new_game()

# Set up the initial game state
func new_game():
	# Set initial dialogue text
	dialogue_label.text = dialogue[page]
	# Start with no visible characters
	dialogue_label.set_visible_characters(0)
	# Start text reveal timer
	timer.start() 
	# Play audio for first dialogue
	play_audio(page)   
	
	# Start background music for the quantum realm
	MusicController.playMusic(ReferenceManager.get_reference("quantum.ogg"))

# source: https://docs.godotengine.org/en/3.2/getting_started/step_by_step/your_first_game.html#enemy-scene
#func _on_StartTimer_timeout():
#	print("start timer end")
	#$ElcitrapTimer.start()
#	print("e timer start")

# Spawn Elcitraps at random intervals
func _on_ElcitrapTimer_timeout():
	# Check if there are still Elcitraps to be released
	if len(trait_queue) > 0:
		# Randomize spawn location along a predefined path
		$EPath/EPathFollow.progress = randi()
		
		# Instantiate a new Elcitrap
		var elcitrap = Elcitrap.instantiate()
		# Initialize Elcitrap with first trait in queue
		elcitrap.init(trait_queue[0])
		# Remove the used trait from the queue
		trait_queue.pop_front()
		add_child(elcitrap)
		
		# Calculate movement direction
		var direction = $EPath/EPathFollow.rotation + PI / 2
		
		# Set Elcitrap's initial position
		elcitrap.position = $EPath/EPathFollow.position
		
		# Add some randomness to direction
		direction += randf_range(-PI / 4, PI / 4)
		elcitrap.rotation = direction
		
		# Set Elcitrap's velocity with some randomness
		elcitrap.linear_velocity = Vector2(randf_range(elcitrap.min_speed, elcitrap.max_speed), 0)
		elcitrap.linear_velocity = elcitrap.linear_velocity.rotated(direction)

# # Check for scene progression each frame
func _process(delta):
	# When all 15 Elcitraps are captured, start end timer
	if total_captured == 15:
		$EndTimer.start()
		# Prevent repeated timer starts
		total_captured = 16

# Handle scene transition when end timer completes
func _on_EndTimer_timeout() -> void:
	# For non-server clients, notify server of readiness
	if not multiplayer.is_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", multiplayer.get_unique_id())
	else:
		# Server directly calls ready_to_start
		ready_to_start(multiplayer.get_unique_id())

# Network RPC to set captured Elcitraps for each player
@rpc("any_peer", "call_local") func set_elcitraps(elcitraps):
	gamestate.elcitraps[multiplayer.get_remote_sender_id()] = elcitraps

# Network RPC to start the next scene
@rpc("any_peer") func start_game():
	get_parent().change_level(next_scene)

# Network RPC to manage player readiness and scene progression
@rpc("any_peer") func ready_to_start(id):
	# Ensure this is only called on the server
	assert(multiplayer.is_server())

	# Add player to ready list if not already there
	if not id in players_ready:
		players_ready.append(id)
	
	# If all players are ready, start the game for everyone
	if players_ready.size() == gamestate.players.size():
		for p in gamestate.players:
			rpc_id(p, "start_game")
		start_game()

# Handle dialogue progression through mouse clicks
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		# If current dialogue is fully revealed
		if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
			# Move to next dialogue page if available
			if page < dialogue.size() - 1:
				page += 1
				dialogue_label.text = dialogue[page]
				dialogue_label.set_visible_characters(0)
				timer.start()  # Restart text reveal
				play_audio(page)  # Play next dialogue audio
			else:
				# Start Elcitrap timer and hide dialogue box
				$ElcitrapTimer.start()
				$DialogueBox.hide()

# Play audio for current dialogue page
func play_audio(page_index):
	# Stop all existing audio players
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()

	# Find and play audio for current page
	var audio_node_name = "AudioStreamPlayer" + str(page_index+1)
	var current_player = get_node(audio_node_name)
	if current_player:
		current_player.play()
	else:
		print("Audio node not found: ", audio_node_name)

# Gradually reveal dialogue text
func _on_Timer_timeout():
	# Incrementally show more characters
	dialogue_label.set_visible_characters(dialogue_label.get_visible_characters() + 1)
	
	# Stop timer when full text is revealed
	if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
		timer.stop()  # Stop timer when all text is revealed
