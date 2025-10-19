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
@export var dominos = []

# Consts for footprint tiles
const num_outer_tiles = 36
const num_inner_tiles = 24
const tiles_per_round = (num_outer_tiles + num_inner_tiles) / num_domino_rounds

var peer = null

#Array to store dictionary keys for loaded data
var keys = []

# Name for my player.
var player_name = "Player"

# Number of CPUs desired to include
# Warning: will softlock scenes besides the Domino Game if set to a val besides 0
# Until bug is fixed, only change value when starting in the Domino Game
var cpuNum = 5

# Tutorial mode flag - Added CS499 Fall 2024
var tutorial_mode = false

# CS499 Fall 2024 - Doesnt work as intented
var tutorial_dominos = [
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

var first_level = "Agency"

var random_seed = 0

# Traits for elcitraps


# Keeping track of previous scene.
# (For UI purposes mainly, back button etc)
var prev_scene = "res://Scenes/GAME_START.tscn"
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
signal connection_succeeded()
signal game_ended()
signal game_error(what)

# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beginss here, tell the connected player that we are here.
	
	# ask host for level and random seed
	rpc_id(1, "get_level")
	rpc_id(1, "get_random_seed")
	
	rpc("register_player", player_name, 0)

# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/World"): # Game is in progress.
		if multiplayer.is_server():
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	emit_signal("connection_succeeded")


# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()


# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	multiplayer.multiplayer_peer = null # Remove peer
	emit_signal("connection_failed")


# Lobby management functions.
@rpc("any_peer", "call_local") func register_player(new_player_name,cpunum):
	var id = multiplayer.get_remote_sender_id()+cpunum
	var CharacterFound = false
	players[id] = new_player_name
	if(SaveManager.loaded_data):
		keys = SaveManager.Save["0"].Players.keys()
		for i in range(len(keys)):
			if(SaveManager.Save["0"].Players[keys[i]] == new_player_name):
				CharacterFound = true
				total_points[id] = SaveManager.Save["0"].Points[keys[i]]
				elcitraps[id] = SaveManager.Save["0"].elcitraps[keys[i]]
				hair[id] = SaveManager.Save["0"].hair[keys[i]]
				clothes[id] = SaveManager.Save["0"].clothes[keys[i]]
				body[id] = SaveManager.Save["0"].body[keys[i]]
				if(SaveManager.Save["0"].lydia_lion.keys().find(keys[i]) != -1):
					lydia_lion[id] = SaveManager.Save["0"].lydia_lion[keys[i]]
				if(SaveManager.Save["0"].alloys.keys().find(keys[i]) != -1):
					alloys[id] = SaveManager.Save["0"].alloys[keys[i]]
				if(SaveManager.Save["0"].footprint_tiles.keys().find(keys[i]) != -1):
					footprint_tiles[id] = SaveManager.Save["0"].footprint_tiles[keys[i]]
				if(SaveManager.Save["0"].wellness_beads.keys().find(keys[i]) != -1):
					wellness_beads[id] = SaveManager.Save["0"].wellness_beads[keys[i]]
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
	emit_signal("player_list_changed")


@rpc("any_peer") func pre_start_game():
	# Change scene.
#	print(players)

	if not multiplayer.is_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", multiplayer.get_unique_id())
	elif players.size() == 1:
		# small loop to add CPUs with unique names and ids
		var cpusAdded = 0
		while cpusAdded < cpuNum and players.size() < 6:
			register_player("CPU_"+str(players.size()),players.size()+1)
			cpusAdded=cpusAdded+1
		post_start_game()


@rpc("any_peer") func post_start_game():
	gamestate.players_ready = []
	var world = load("res://Scenes/Level_Scenes/Manager.tscn")
	
			
	if multiplayer.get_unique_id() != 1:
		for top in range(10):
			for bottom in range(top+1):
				dominos.append([bottom, top])
		seed(random_seed)
#		print(random_seed)
		dominos.shuffle()
#		print(dominos)
	
	get_tree().change_scene_to_packed(world)

# tell host we're ready to start
@rpc("any_peer") func ready_to_start(id):
	assert(multiplayer.is_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size()-1:
		for p in players:
			if p != multiplayer.get_unique_id():
				rpc_id(p, "post_start_game")
		post_start_game()

func host_game(new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.multiplayer_peer = peer
	
	var id = multiplayer.get_unique_id()
	
	rpc("register_player", player_name, 0)

func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer
	
# host sends level to player who asked
@rpc("any_peer") func get_level():
	var id = get_tree().get_remote_sender_id()
	rpc_id(id, "set_level", first_level)
	
# player sets their level
@rpc("any_peer") func set_level(level):
	first_level = level
	
# host sends random seed to player who asked
@rpc("any_peer") func get_random_seed():
	var id = get_tree().get_remote_sender_id()
	rpc_id(id, "set_random_seed", random_seed)
	
# player sets their random seed
@rpc("any_peer") func set_random_seed(rando_seed):
	random_seed = rando_seed
#	print("seed: ", random_seed)

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

# host tells everyone to start the game
func begin_game():
	if tutorial_mode:
		start_tutorial()
	else:
		assert(multiplayer.is_server())

		# Call to pre-start game with the spawn points.
		for p in players:
			if p != multiplayer.get_unique_id():
				rpc_id(p, "pre_start_game")

		pre_start_game()

#Added CS499 Fall 2024
func start_tutorial():
	var tutorial_scene = load("res://Scenes/Level_Scenes/Manager.tscn")
	player_name = "Tutorial" #Set the player name to Tutorial
	dominos = tutorial_dominos
	random_seed = 12345 #Fixed Seed for Tutorial consistency
	
	get_tree().change_scene_to_packed(tutorial_scene)

func get_tutorial_mode():
	return tutorial_mode

func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	emit_signal("game_ended")
	players.clear()
	
# New functions added by Spring 2024 CS-499 Group
func save_scene_path(scene_path):
	prev_scene = scene_path

func _ready():
	get_tree().connect("peer_connected", Callable(self, "_player_connected"))
	get_tree().connect("peer_disconnected", Callable(self, "_player_disconnected"))
	get_tree().connect("connected_to_server", Callable(self, "_connected_ok"))
	get_tree().connect("connection_failed", Callable(self, "_connected_fail"))
	get_tree().connect("server_disconnected", Callable(self, "_server_disconnected"))
