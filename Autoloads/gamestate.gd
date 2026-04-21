# singleton with lots of game/player data stored
# also handles initial player/host creation

extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 6

# Consts for domino phase
const num_domino_rounds = 6

# list of [top number, bottom number] lists
@export var dominoes = []

# Consts for footprint tiles
const num_outer_tiles = 36
const num_inner_tiles = 24
const tiles_per_round = int(float(num_outer_tiles + num_inner_tiles) / num_domino_rounds)

var peer = null

#Array to store dictionary keys for loaded data
var keys = []

# Name for my player.
var player_name = "Player"

# Number of CPUs desired to include
# Warning: will softlock scenes besides the Domino Game if set to a val besides 0
# Until bug is fixed, only change value when starting in the Domino Game
var cpuNum = 0

# Tutorial mode flag - Added CS499 Fall 2024
var tutorial_mode = false

# CS499 Fall 2024 - Doesnt work as intented
var tutorial_dominoes = [
	[0, 1], [1, 2], [2, 3], [3, 4]  # Example domino chain
]

# Names for remote players in id:name format.
var players = {}
var players_ready = []

# Character Data in id:data format
@export var total_points = {}
@export var lydia_lion = {}
@export var alloys = {}
@export var footprint_tiles = {}
@export var wellness_beads = {}
@export var elcitraps = {}
@export var hair = {}
@export var clothes = {}
@export var body = {}
@export var player_icon = {}

var first_level = "Agency"

var random_seed = 0

# Traits for elcitraps


# Keeping track of previous scene.
# (For UI purposes mainly, back button etc)
var prev_scene = "res://Scenes/Core/GAME_START.tscn"
var title_screen_click_flag = false


# Chunk Size/Dimensions
const DIMENSION = Vector3(16, 64, 16)

# Size of atlas
# Current texture atlas has size 3 x 2
const TEXTURE_ATLAS_SIZE = Vector2(3, 2)

# Enumerator for block faces
enum {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	SOLID
}

# Enumerator for all blocks within game
# Update when adding new blocks
enum {
	AIR,
	DIRT,
	GRASS,
	STONE,
	CAMPFIRE
}

# Dictionary for mapping blocks to corresponding textures in atlas
# Update when adding new blocks or changing texture atlas
const types = {
	AIR:{
		SOLID: false,
	},
	DIRT:{
		SOLID: true,
		TOP: Vector2(2, 0),
		BOTTOM: Vector2(2, 0),
		LEFT: Vector2(2, 0),
		RIGHT: Vector2(2,0),
		FRONT: Vector2(2, 0),
		BACK: Vector2(2, 0),
	},
	GRASS:{
		SOLID: true,
		TOP: Vector2(0, 0),
		BOTTOM: Vector2(2, 0),
		LEFT: Vector2(1, 0),
		RIGHT: Vector2(1,0),
		FRONT: Vector2(1, 0),
		BACK: Vector2(1, 0),
	},
	STONE:{
		SOLID: true,
		TOP: Vector2(0, 1),
		BOTTOM: Vector2(0, 1),
		LEFT: Vector2(0, 1),
		RIGHT: Vector2(0, 1),
		FRONT: Vector2(0, 1),
		BACK: Vector2(0, 1),
	},
	CAMPFIRE:{
		SOLID: true,
		TOP: Vector2(1,1),
		BOTTOM: Vector2(1, 1),
		LEFT: Vector2(2, 1),
		RIGHT: Vector2(2, 1),
		FRONT: Vector2(2, 1),
		BACK: Vector2(2, 1),
	}
}

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal game_ended()
signal game_error(what)
signal join_accepted_signal
signal hot_join_accepted_signal

var game_in_progress = false
var is_hot_joining = false

# Callback from SceneTree.
func _player_connected(_id):
	# Registration of a client begins here, tell the connected player that we are here.
	
	# ask host for level and random seed
	rpc_id(1, "get_level")
	rpc_id(1, "get_random_seed")
	
	rpc("register_player", player_name, 0)

# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/Manager"): # Game is in progress.
		if multiplayer.is_server() and players.has(id):
			# Turn the dropped player into a CPU
			var original_name = players[id]
			if not str(original_name).contains("CPU"):
				var cpu_name = original_name + " (CPU)"
				
				# Generate a protected negative integer ID so Native ENet doesn't recycle this ID onto a new player later!
				var safe_cpu_id = -(id + 1000)
				rpc("sync_player_id_change", id, safe_cpu_id, cpu_name)
				
				# Map CPU hands first BEFORE sending the RPC (so AI logic is ready)
				var manager = get_node_or_null("/root/Manager")
				if manager != null and "current_level" in manager:
					var world = manager.current_level
					if world != null:
						if "all_player_hands" in world and world.all_player_hands.has(safe_cpu_id):
							if "cpu_hands" in world:
								# Give the CPU the human's remaining hand so it can play
								world.cpu_hands[safe_cpu_id] = world.all_player_hands[safe_cpu_id].duplicate(true)
						
				# Now that the CPU is mapped, broadcast the name change which also triggers the turn label execution
				rpc("update_player_name", safe_cpu_id, cpu_name)
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)

# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()

# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	multiplayer.multiplayer_peer = null # Remove peer
	emit_signal("connection_failed")

# Lobby management functions.
@rpc("any_peer", "call_local") func register_player(new_player_name, cpunum):
	var id = multiplayer.get_remote_sender_id()
	
	if id == 0:
		id = multiplayer.get_unique_id()

	# PREVENT GHOSTS: Clients should never blindly accept human registrations mid-game
	# because the server might reject them, but the clients will never natively erase them!
	# Mid-game human additions are ONLY handled securely by the server's explicit sync_player_id_change.
	var is_cpu = str(new_player_name).contains("CPU")
	if not multiplayer.is_server() and game_in_progress and not is_cpu:
		return

	var target_reclaim_id = -1
	# --- Server Handshake Gatekeeper ---
	if multiplayer.is_server():

		# Shield existing human players from getting processed again during retro-active peer discoveries
		if not is_cpu and players.has(id):
			return
			
		if not is_cpu and id != 1:
			var conflict = false
			for p_id in players:
				if p_id == id:
					continue # Ignore self for duplicate name checks
					
				var active_name = str(players[p_id])
				if active_name == str(new_player_name):
					conflict = true
					break
				elif active_name == str(new_player_name) + " (CPU)":
					target_reclaim_id = p_id
					break
			
			if conflict:
				rpc_id(id, "join_rejected", "Name already taken!")
				return
				
			if game_in_progress:
				if target_reclaim_id != -1:
					# Swap the CPU's ID to this new client's ID so they can take over
					rpc("sync_player_id_change", target_reclaim_id, id, new_player_name)
					
					var state_package = {
						"players": players,
						"player_icon": player_icon,
						"lydia_lion": lydia_lion,
						"alloys": alloys,
						"footprint_tiles": footprint_tiles,
						"wellness_beads": wellness_beads,
						"elcitraps": elcitraps,
					}
					rpc_id(id, "push_full_gamestate", state_package)
					return
				else:
					rpc_id(id, "join_rejected", "Game already in progress!")
					return
			else:
				if target_reclaim_id != -1:
					# Client reconnecting in the lobby
					rpc("sync_player_id_change", target_reclaim_id, id, new_player_name)
					rpc_id(id, "join_accepted")
					return
					
			rpc_id(id, "join_accepted")
		
		# CPUs always bypass the lock
		elif is_cpu:
			pass
	
	id += cpunum
	if players.has(id):
		return
	var CharacterFound = false
	players[id] = new_player_name
	if(SaveManager.loaded_data):
		keys = SaveManager.Save["0"].Players.keys()
		for i in range(len(keys)):
			if(SaveManager.Save["0"].Players[keys[i]] == new_player_name):
				CharacterFound = true
				total_points[id] = SaveManager.Save["0"].Points[keys[i]]
				elcitraps[id] = SaveManager.Save["0"].elcitraps[keys[i]]
				hair[id] = int(SaveManager.Save["0"].hair[keys[i]])
				clothes[id] = int(SaveManager.Save["0"].clothes[keys[i]])
				body[id] = int(SaveManager.Save["0"].body[keys[i]])
				if SaveManager.Save["0"].lydia_lion.has(keys[i]):
					lydia_lion[id] = SaveManager.Save["0"].lydia_lion[keys[i]]
				if SaveManager.Save["0"].alloys.has(keys[i]):
					alloys[id] = SaveManager.Save["0"].alloys[keys[i]]
				if SaveManager.Save["0"].footprint_tiles.has(keys[i]):
					footprint_tiles[id] = SaveManager.Save["0"].footprint_tiles[keys[i]]
				if SaveManager.Save["0"].wellness_beads.has(keys[i]):
					wellness_beads[id] = SaveManager.Save["0"].wellness_beads[keys[i]]
				if SaveManager.Save["0"].player_icon.has(keys[i]):
					player_icon[id] = SaveManager.Save["0"].player_icon[keys[i]]
		if(not CharacterFound):
			total_points[id] = 0
			elcitraps[id] = []
			hair[id] = 0
			clothes[id] = 0
			body[id] = 0
	else:
		total_points[id] = 0
		elcitraps[id] = []
		hair[id] = 0
		clothes[id] = 0
		body[id] = 0
	emit_signal("player_list_changed")

func unregister_player(id):
	players.erase(id)
	if player_icon.has(id):
		player_icon.erase(id)
	emit_signal("player_list_changed")

@rpc("any_peer", "call_local") func update_player_name(id: int, new_name: String):
	if players.has(id):
		players[id] = new_name
		emit_signal("player_list_changed")
		
		# Immediately refresh the turn label if the game is active, so clients see "(CPU)" appended mid-turn
		if has_node("/root/Manager"):
			var manager = get_node("/root/Manager")
			if "current_level" in manager and manager.current_level != null:
				if manager.current_level.has_method("_update_turn_label"):
					manager.current_level._update_turn_label()

@rpc("any_peer", "call_local", "reliable")
func sync_player_id_change(old_id: int, new_id: int, new_name: String):
	players[new_id] = new_name
	if players.has(old_id): players.erase(old_id)
	
	for dict in [total_points, lydia_lion, alloys, footprint_tiles, wellness_beads, elcitraps, hair, clothes, body, player_icon]:
		if dict.has(old_id):
			dict[new_id] = dict[old_id]
			dict.erase(old_id)
			
	emit_signal("player_list_changed")
	
	if has_node("/root/Manager"):
		var manager = get_node("/root/Manager")
		var world_node = null
		if "current_level" in manager: world_node = manager.current_level
		if world_node:
			if world_node.get("cpu_hands") != null and world_node.cpu_hands.has(old_id):
				world_node.cpu_hands.erase(old_id)
			if world_node.get("all_player_hands") != null and world_node.all_player_hands.has(old_id):
				world_node.all_player_hands[new_id] = world_node.all_player_hands[old_id]
				world_node.all_player_hands.erase(old_id)
			
			if world_node.get("sorted_players") != null:
				var idx = world_node.sorted_players.find(old_id)
				if idx != -1:
					world_node.sorted_players[idx] = new_id

func disconnect_network():
	# Explicitly close the ENet connection so the server knows we left
	if peer != null:
		peer.close()
		peer = null
		
	multiplayer.multiplayer_peer = null
	
	game_in_progress = false
	
	# Scrub the local data for the next time they join
	players.clear()
	player_icon.clear()
	players_ready.clear()

@rpc("any_peer", "call_local", "reliable") 
func pre_start_game():
	if multiplayer.is_server():
		# Host creates the CPUs
		var starting_size = players.size()
		var cpus_needed = 6 - starting_size
		
		for i in range(cpus_needed):
			var cpu_number = starting_size + i + 1
			var safe_offset = -(10 + i) 
			rpc("register_player", "CPU_" + str(cpu_number), safe_offset)
			
		# Wait for the network to sync the new CPU names to everyone
		await get_tree().create_timer(0.5).timeout
		
		# We use call_local so the Host does it too.
		rpc("prepare_client_deck", random_seed)
		
		# Now that everyone has CPUs and Decks, pull them into the scene
		rpc("post_start_game")

@rpc("any_peer")
func prepare_client_deck(r_seed):
	# Clients generate the same shuffled deck as the host
	dominoes = []
	for top in range(10):
		for bottom in range(top+1):
			dominoes.append([bottom, top])
	seed(r_seed)
	dominoes.shuffle()


@rpc("any_peer", "call_local", "reliable")
func post_start_game():
	var world = load("res://Scenes/Core/Manager.tscn")
	get_tree().change_scene_to_packed(world)

func host_single_player(new_player_name):
	# Because the code assumes a multiplayer network setup, it is easiest
	# to create a "singleplayer server" with just one player for singleplayer
	# games
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	
	# Using port 0 tells the OS to pick an available ephemeral port
	# Set MAX_PEERS to 1 since it's singleplayer
	peer.create_server(0, 1) 
	multiplayer.multiplayer_peer = peer
	rpc("register_player", player_name, 0)

func host_game(new_player_name) -> Error:
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(DEFAULT_PORT, MAX_PEERS)
	# If the port is in use or creation fails, abort!
	if err != OK:
		peer = null
		return err
	multiplayer.multiplayer_peer = peer
	rpc("register_player", player_name, 0)
	return OK
	
func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, DEFAULT_PORT)
	# If it fails instantly (e.g., invalid IP format), abort and notify UI
	if err != OK:
		_connected_fail()
		return
	multiplayer.multiplayer_peer = peer

@rpc("authority", "call_local") func join_accepted():
	# Only clients care about this signal (the host handles their own UI)
	if not multiplayer.is_server():
		emit_signal("join_accepted_signal")

@rpc("authority", "call_local") func push_full_gamestate(state_package: Dictionary):
	if not multiplayer.is_server():
		players = state_package["players"]
		player_icon = state_package["player_icon"]
		lydia_lion = state_package["lydia_lion"]
		alloys = state_package["alloys"]
		footprint_tiles = state_package["footprint_tiles"]
		wellness_beads = state_package["wellness_beads"]
		elcitraps = state_package["elcitraps"]
		
		is_hot_joining = true
		game_in_progress = true
		emit_signal("hot_join_accepted_signal")

@rpc("authority", "call_local") func join_rejected(reason: String):
	disconnect_network()
	emit_signal("game_error", reason)

# host sends level to player who asked
@rpc("any_peer") func get_level():
	var id = multiplayer.get_remote_sender_id()
	rpc_id(id, "set_level", first_level)
	
# player sets their level
@rpc("any_peer") func set_level(level):
	first_level = level
	
# host sends random seed to player who asked
@rpc("any_peer") func get_random_seed():
	var id = multiplayer.get_remote_sender_id()
	rpc_id(id, "set_random_seed", random_seed)
	
# player sets their random seed
@rpc("any_peer") func set_random_seed(rando_seed):
	random_seed = rando_seed


func get_player_list():
	return players.values()

func get_player_name():
	return player_name

# host tells everyone to start the game
func begin_game():
	game_in_progress = true
	if tutorial_mode:
		start_tutorial()
	else:
		assert(multiplayer.is_server())
		# We only call pre_start_game locally on the server. 
		# The server will then tell clients what to do via RPC.
		pre_start_game()

#Added CS499 Fall 2024
func start_tutorial():
	var tutorial_scene = load("res://Scenes/Core/Manager.tscn")
	player_name = "Tutorial" #Set the player name to Tutorial
	dominoes = tutorial_dominoes
	random_seed = 12345 #Fixed Seed for Tutorial consistency
	
	get_tree().change_scene_to_packed(tutorial_scene)

func get_tutorial_mode():
	return tutorial_mode

func end_game():
	game_in_progress = false
	if has_node("/root/Manager"): # Game is in progress.
		# End it
		get_node("/root/Manager").queue_free()

	emit_signal("game_ended")
	players.clear()
	
# New functions added by Spring 2024 CS-499 Group
func save_scene_path(scene_path):
	prev_scene = scene_path

func _ready():
	if SaveManager.load_game():
		var data = SaveManager.Save["0"]
		if data.has("PlayerName"):
			player_name = data["PlayerName"]
	else:
		var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		var random_id = ""
		for i in range(4):
			random_id += chars[randi() % chars.length()]
		player_name = "Player_" + random_id
	
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
