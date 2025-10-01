# character creation scene in Blombos Cave
extends Node2D

# Export variables to configure scene and prefabs
@export var next_scene: PackedScene # Scene to load after character creation
@export var Elcitrap: PackedScene # Prefab for Elcitrap objects

@export var hair_count = 12 # Total number of hair styles available
@export var body_count = 4 # Total number of body types available
@export var clothes_count = 5 # Total number of clothing options

# Signal to trigger animations
signal trigger_animation(anim_name)

# Track currently selected customization options
var hair_num = 0 # Current hair style index
var body_num = 0 # Current body type index
var clothes_num = 0 # Current clothing option index

# Track players who are ready to proceed
var players_ready = []

# Initialize the scene when it enters the scene tree
func _ready() -> void:
	#$AnimationPlayer.play("Zoom")
	#emit_signal("trigger_animation", "Screen_Unwipe") 
	
	# Populate elcitraps with data from previous scene
	for i in range(len(gamestate.elcitraps[multiplayer.get_unique_id()])):
		var elcitrap = Elcitrap.instantiate()
		add_child(elcitrap)
		elcitrap.position = Vector2(60, 60*i + 200)
		elcitrap.init((gamestate.elcitraps[multiplayer.get_unique_id()])[i])
		
	# Start playing background music for the cave scene
	MusicController.playMusic(ReferenceManager.get_reference("cave.ogg"))

# Utility function to handle circular indexing for customization options
func mod(num, maximum):
	if num < 0:
		return maximum-1
	elif num > maximum-1:
		return 0
	else:
		return num

# Hair customization - move left through hair styles
func _on_hair_left_pressed() -> void:
	# Decrement hair style index, wrapping around if needed
	hair_num = mod(hair_num - 1, hair_count)
	# Update front and back hair textures
	$front_hair.set_texture(load(ReferenceManager.get_reference("front_hair/" + str(hair_num) + ".png")))
	$back_hair.set_texture(load(ReferenceManager.get_reference("back_hair/" + str(hair_num) + ".png")))

# Hair customization - move right through hair styles
func _on_hair_right_pressed() -> void:
	# Increment hair style index, wrapping around if needed
	hair_num = mod(hair_num + 1, hair_count)
	# Update front and back hair textures
	$front_hair.set_texture(load(ReferenceManager.get_reference("front_hair/" + str(hair_num) + ".png")))
	$back_hair.set_texture(load(ReferenceManager.get_reference("back_hair/" + str(hair_num) + ".png")))

# Body customization - move left through body types
func _on_body_left_pressed() -> void:
	# Decrement body type index, wrapping around if needed
	body_num = mod(body_num - 1, body_count)
	# Update body texture
	$body.set_texture(load(ReferenceManager.get_reference("bodies/" + str(body_num) + ".png")))

# Body customization - move right through body types
func _on_body_right_pressed() -> void:
	# Increment body type index, wrapping around if needed
	body_num = mod(body_num + 1, body_count)
	# Update body textures
	$body.set_texture(load(ReferenceManager.get_reference("bodies/" + str(body_num) + ".png")))

# Clothing customization - move left through clothing options
func _on_clothes_left_pressed() -> void:
	# Decrement clothing option index, wrapping around if needed
	clothes_num = mod(clothes_num - 1, clothes_count)
	# Update clothing texture
	$clothes.set_texture(load(ReferenceManager.get_reference("clothes/" + str(clothes_num) + ".png")))

# Clothing customization - move right through clothing options
func _on_clothes_right_pressed() -> void:
	# Increment clothing option index, wrapping around if needed
	clothes_num = mod(clothes_num + 1, clothes_count)
	# Update clothing texture
	$clothes.set_texture(load(ReferenceManager.get_reference("clothes/" + str(clothes_num) + ".png")))

# Handling proceeding to the next scene
func _on_next_pressed() -> void:
	# Synchronize character features across the network
	rpc("set_features", hair_num, body_num, clothes_num)
	
	# If not the server, inform the server that this player is ready
	if not multiplayer.is_server():
		rpc_id(1, "ready_to_start", multiplayer.get_unique_id())
	else:
		# If server, immediately mark as ready
		ready_to_start(multiplayer.get_unique_id())

# Toggle visibility of a color rect during animation
func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	$ZIndexSetter/ColorRect.visible = !$ZIndexSetter/ColorRect.visible 

# Network RPC to set character features for each player
@rpc("any_peer", "call_local") func set_features(hair, body, clothes):
	# Store selected features in the gamestate for the current player
	gamestate.hair[multiplayer.get_remote_sender_id()] = hair
	gamestate.body[multiplayer.get_remote_sender_id()] = body
	gamestate.clothes[multiplayer.get_remote_sender_id()] = clothes

# Network RPC to start the game
@rpc("any_peer") func start_game():
	get_parent().change_level(next_scene)

# Network RPC to track player readiness and start the game when all players are ready
@rpc("any_peer") func ready_to_start(id):
	# Ensure this is only called on the server
	assert(multiplayer.is_server())
	
	# Add this player to the list of ready players if not already added
	if not id in players_ready:
		players_ready.append(id)
	
	# If all players are ready, notify each player to start the game
	if players_ready.size() == gamestate.players.size():
		for p in gamestate.players:
			rpc_id(p, "start_game")
		start_game()
