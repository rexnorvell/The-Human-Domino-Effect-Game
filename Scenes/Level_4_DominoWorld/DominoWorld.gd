# domino level scene
class_name DominoWorld
extends Node2D

const HAND_SCALE = Vector2(0.22, 0.22)
const PLACED_SCALE = Vector2(0.08, 0.08)
const ROTATION_OFFSET_DEG := 90.0 # rotate pieces 90° clockwise
const HAND_SPACING := 85 # pixels between hand dominoes

# --- Hardcoded step directions by path, in degrees ---
# Order requested: Path1, Path2, Path3?, Path4, Path5, Path6, ?, SunsetPath
#const PATH_ANGLE_DEGREES := [292.5, 247.5, 337.5, 157.5, 112.5, 67.5, 202.5, 22.5]
const PATH_ANGLE_DEGREES := [292.5, 202.5, 337.5, 157.5, 112.5, 22.5, 247.5, 67.5]

# How far to move each successive domino along that direction
const STEP_PIXELS := 24.0 # tune for your art scale

# Keep a per-path step count; replaces placed_domino_offset
var path_step_count := [0, 0, 0, 0, 0, 0, 0, 0]
# Tracks which player trains (0-5) are currently open for anyone to play on
var train_open := [false, false, false, false, false, false, false, false]

@export var Domino: PackedScene
# NOTE: If domino game performance is low, try switching to preload
#const FootprintTile = preload("res://Scenes/Level_4_DominoWorld/FootprintTile.gd")
var FootprintTile = load(ReferenceManager.get_reference("FootprintTile.gd"))
var footprint_tile_ring = null
# NOTE: If domino game performance is low, try switching to preload
#const tower = preload("res://Scenes/Level_4_DominoWorld/Tower.gd")
var tower = load(ReferenceManager.get_reference("Tower.gd"))
var sorted_players = []

var turn = 0 # whose turn is it, indexed from 0 on
var hand = []
var dominos = [] + gamestate.dominos
var self_num = 0 # player's number, indexed from 1 on
var selected_domino = null # currently selected domino
var center_num = 0 # current round number
var num_placed = 0

var cpu_hands = {} # The Host stores CPU hands here
var all_player_hands = {}  # Host tracks ALL player hands (human + CPU) for stalemate detection
var _consecutive_help_count := 0  # Tracks consecutive Help presses without a placement

# (Fall 2025) added variables
var can_place = true # to check if currently selected domino is a double
var hand_dominos = [] # track dominos in hand numerically

var path_ends = [0, 0, 0, 0, 0, 0, 0, 0] # last number on domino chain in each path
var end_dominos = [null, null, null, null, null, null, null, null] # last domino on domino chain in each path

var position_table: Array[Vector2] = []
var prev_domino_size = 0
var _next_slot_indicators: Array[Node2D] = []

var bonusWords = ["Bonus", "Bonus2"]
var usedBonus = ["ABC123"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Start.visible = false
	$Next.visible = false
	# (Fall 2025) set the visibility of added buttons accordingly
	$Help.visible = false
	$Reset.visible = false
	intialize_tower()
	_init_players()
	dominos.erase([0, 0])
	
	var center_area := $CentralDomino.get_node_or_null("Area2D")
	if center_area:
		center_area.input_pickable = false
		center_area.monitoring = false
		
#  Sets up and resolves players and their resulting nodes
func _init_players() -> void:
	print("=== _init_players() START ===")
	
	# initialize footprint tile ring
	footprint_tile_ring = load(ReferenceManager.get_reference("FootprintTileRing.gd")).new(self)
	footprint_tile_ring.position = $Board.position
	add_child(footprint_tile_ring)
	print("Added footprint_tile_ring at: ", footprint_tile_ring.position)

	# sort players
	sorted_players.clear()
	for p in gamestate.players:
		sorted_players.append(p)
	sorted_players.sort()
	print("sorted_players: ", sorted_players)

	# Build a deterministic pool of available player icon filenames
	var all_icon_names: Array[String] = []
	for key in ReferenceManager.refDict.keys():
		if key.begins_with("player_icons/"):
			var icon_file = key.get_slice("/", 1)
			# Explicitly ban the sun icons from being used by players/CPUs
			if icon_file != "sun.png" and icon_file != "sunshine.png":
				all_icon_names.append(icon_file)
	all_icon_names.sort()

	# Gather icons already explicitly chosen by any player 
	var chosen_icon_names: Array[String] = []
	for pid in gamestate.players:
		var explicit_choice: String = gamestate.player_icon.get(pid, "")
		if explicit_choice != "" and all_icon_names.has(explicit_choice):
			if chosen_icon_names.find(explicit_choice) == -1:
				chosen_icon_names.append(explicit_choice)

	# Shuffle for icons not chosen by players
	var remaining_icon_pool: Array[String] = []
	for name in all_icon_names:
		if chosen_icon_names.find(name) == -1:
			remaining_icon_pool.append(name)
	remaining_icon_pool.shuffle()

	# Reserve local player's chosen icon (fallback to basket.png)
	var my_icon_name: String = gamestate.player_icon.get(multiplayer.get_unique_id(), "basket.png")

	# Deterministic per-player icon assignment map to avoid randomness differences across peers
	var assigned_icons := {}

	var ind := 1

	for player_id in sorted_players:
		var bubble_path := "Character Bubble" + str(ind)
		print("\n--- setting up ", bubble_path, " for player_id=", player_id, " ---")
		
		var bubble_node = get_node_or_null(bubble_path)
		if bubble_node and bubble_node.has_method("setup_character"):
			bubble_node.setup_character(player_id)

		# Resolve icon filename for this player
		var icon_name: String = ""
		if assigned_icons.has(player_id):
			icon_name = assigned_icons[player_id]
		else:
			var existing_choice: String = gamestate.player_icon.get(player_id, "")
			# Respect any explicit choice 
			if existing_choice != "" and all_icon_names.has(existing_choice):
				# Respect any explicit choice if present and available
				icon_name = existing_choice
				remaining_icon_pool.erase(existing_choice)
			elif player_id == multiplayer.get_unique_id():
				icon_name = my_icon_name
			else:
				# Assign randomly but uniquely from remaining pool
				if remaining_icon_pool.size() > 0:
					icon_name = remaining_icon_pool.pop_front()
				else:
					icon_name = my_icon_name # fallback
			assigned_icons[player_id] = icon_name
		print("player_id ", player_id, " resolved icon_name = ", icon_name)
		
		var icon_texture: Texture2D = null
		var ref_key := "player_icons/" + icon_name
		if ReferenceManager.refDict.has(ref_key):
			var icon_path: String = str(ReferenceManager.get_reference(ref_key))
			print(" icon_path from ReferenceManager = ", icon_path)
			if ResourceLoader.exists(icon_path):
				var maybe_tex = load(icon_path)
				if maybe_tex is Texture2D:
					icon_texture = maybe_tex
					print(" loaded icon texture OK")
				else:
					print(" loaded resource is NOT Texture2D")
			else:
				print(" ResourceLoader: no such path for ", icon_path)
		else:
			print(" ref_key missing from ReferenceManager: ", ref_key)

		# Apply icon ONLY to the small avatar face node; preserve previous on-screen size
		var face_path := bubble_path + "/face"
		if has_node(face_path):
			var face_node = get_node(face_path)
			print(" found face node at ", face_path, " class=", face_node.get_class())
			if icon_texture != null:
				if face_node is Sprite2D:
					var prev_tex: Texture2D = face_node.texture
					var prev_size: Vector2 = Vector2(64, 64)
					if prev_tex != null:
						prev_size = prev_tex.get_size()
					var prev_scale: Vector2 = face_node.scale
					face_node.texture = icon_texture
					var new_size := icon_texture.get_size()
					if new_size.x > 0.0 and new_size.y > 0.0:
						var target_px := Vector2(prev_size.x * prev_scale.x, prev_size.y * prev_scale.y)
						var new_scale := Vector2(target_px.x / new_size.x, target_px.y / new_size.y)
						face_node.scale = new_scale
					face_node.centered = true
					print("  -> Sprite2D.texture applied to face with scale=", face_node.scale)
				elif face_node is TextureRect:
					face_node.texture = icon_texture
					face_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					print("  -> TextureRect.texture applied to face (keep aspect)")
				else:
					print("  WARNING: face node type doesn't support texture assignment directly")
		else:
			print(" WARNING: no face node at ", face_path)

		# IMPORTANT: hide other layered parts completely so they can't draw giant art
		var parts_to_hide := [
			"/front_hair",
			"/back_hair",
			"/body",
			"/clothes"
		]
		for rel in parts_to_hide:
			var full_path: String = bubble_path + rel
			if has_node(full_path):
				var n = get_node(full_path)
				n.visible = false
				print(" hid node: ", full_path, " class=", n.get_class())

		# Name in popup (still fine to set)
		var popup_name_path := bubble_path + "/Score/Button/Popup/Name_text"
		if has_node(popup_name_path):
			get_node(popup_name_path).set_text(gamestate.players[player_id])
			print(" set popup name for ", bubble_path, " = ", gamestate.players[player_id])

		# elcitraps (unchanged)
		var traps = gamestate.elcitraps[player_id]
		for i in range(len(traps)):
			var trap_node_path := bubble_path + "/Score/Button/Popup/elcitrap" + str(i)
			if has_node(trap_node_path):
				get_node(trap_node_path).init(traps[i])
				print(" init elcitrap ", i, " for ", bubble_path)

		# scores if loaded
		if SaveManager.loaded_data:
			var score_base := bubble_path + "/Score/Button/Popup/"
			var lydia_path := score_base + "Lydia_number"
			var well_path := score_base + "Wellness_number"
			var alloy_path := score_base + "Alloy_number"
			var foot_path := score_base + "Footprint_number"

			if has_node(lydia_path):
				if gamestate.lydia_lion.keys().find(player_id) == -1:
					get_node(lydia_path).text = "0"
				else:
					get_node(lydia_path).text = str(gamestate.lydia_lion[player_id])
				print("  Lyd score set on ", lydia_path)

			if has_node(well_path):
				if gamestate.wellness_beads.keys().find(player_id) == -1:
					get_node(well_path).text = "0"
				else:
					get_node(well_path).text = str(gamestate.wellness_beads[player_id])
				print("  Well score set on ", well_path)

			if has_node(alloy_path):
				if gamestate.alloys.keys().find(player_id) == -1:
					get_node(alloy_path).text = "0"
				else:
					get_node(alloy_path).text = str(gamestate.alloys[player_id])
				print("  Alloy score set on ", alloy_path)

			if has_node(foot_path):
				if gamestate.footprint_tiles.keys().find(player_id) == -1:
					get_node(foot_path).text = "0"
				else:
					get_node(foot_path).text = str(gamestate.footprint_tiles[player_id])
				print("  Footprint score set on ", foot_path)

		# self / path visibility logic (unchanged)
		if player_id == multiplayer.get_unique_id():
			self_num = ind - 1
			var path_node_self = get_node_or_null("Path" + str(ind))
			if path_node_self:
				path_node_self.visible = true
				print(" made Path", ind, " visible for SELF")
			else:
				print(" could not find Path", ind, " for SELF, dumping children:")
				for child in get_children():
					print("    child: ", child.name)
		else:
			var other_path_node = get_node_or_null("Path" + str(ind))
			if other_path_node:
				other_path_node.temp = true
				print(" marked Path", ind, " as temp for OTHER")

		ind += 1

	# remove any unused character sprites
	for i in range(ind, 7):
		var unused_path := "Character Bubble" + str(i)
		if has_node(unused_path):
			get_node(unused_path).queue_free()
			print(" removed unused ", unused_path)

	# Replace decorative board faces with unused player icons
	var board_face_nodes = {"sunrise": "sun.png", "sunset": "sunshine.png"}
	for node_name in board_face_nodes:
		var face_sprite := get_node_or_null(node_name)
		if face_sprite and face_sprite is Sprite2D:
			var assigned_icon_name: String = my_icon_name
			assigned_icon_name = board_face_nodes[node_name]
			var ref_key_board := "player_icons/" + assigned_icon_name
			if ReferenceManager.refDict.has(ref_key_board):
				var icon_path_board: String = str(ReferenceManager.get_reference(ref_key_board))
				if ResourceLoader.exists(icon_path_board):
					var prev_tex_b: Texture2D = face_sprite.texture
					var prev_size_b: Vector2 = Vector2(64, 64)
					if prev_tex_b != null:
						prev_size_b = prev_tex_b.get_size()
					var prev_scale_b: Vector2 = face_sprite.scale
					var new_tex_b = load(icon_path_board)
					if new_tex_b is Texture2D:
						face_sprite.texture = new_tex_b
						var new_size_b: Vector2 = (new_tex_b as Texture2D).get_size()
						if new_size_b.x > 0.0 and new_size_b.y > 0.0:
							var target_px_b := Vector2(prev_size_b.x * prev_scale_b.x, prev_size_b.y * prev_scale_b.y)
							var new_scale_b := Vector2(target_px_b.x / new_size_b.x, target_px_b.y / new_size_b.y)
							face_sprite.scale = new_scale_b
						print(" Replaced board face ", node_name, " with icon ", assigned_icon_name)
					else:
						print(" WARNING: loaded non-texture for board face ", node_name)
				else:
					print(" WARNING: icon path for board face not found: ", icon_path_board)
			else:
				print(" WARNING: ref key missing for board face: ", ref_key_board)

	MusicController.playMusic(ReferenceManager.get_reference("main.ogg"))
	print("Started music")

	# Host sees Start button
	if multiplayer.get_unique_id() == 1:
		$Start.visible = true
		print("Host detected, Start button visible")

	print("Turn label set to ", $Turn.text)
	print("=== _init_players() END ===")


func _on_Start_pressed() -> void:
	if (SaveManager.loaded_data):
		for i in range(0, SaveManager.Save["0"].Current_Round):
			next_round()
	else:
		SaveManager.Save["0"].Current_Round = 0
	
	randomize_turn()
		
	setup_dominos()
	$Start.queue_free()
	
	if (self_num == 0):
		$Next.visible = true
		
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))

func randomize_turn():
	turn = randi() % gamestate.players.size()
	rpc("sync_turn", turn)
	sync_turn(turn)

#Modified values to give out 9 dominos rather than 7.
func setup_dominos():
	# Only the host is allowed to deal dominoes
	if not multiplayer.is_server():
		return

	# Deal for the Host
	var my_hand = []
	for i in range(9):
		my_hand.append(dominos.pop_front())
	all_player_hands[1] = my_hand.duplicate(true)

	# Deal for Clients and CPUs
	for p in gamestate.players:
		if p != 1:
			var client_hand = []
			for i in range(9):
				client_hand.append(dominos.pop_front())

			# Store ALL player hands on host for stalemate detection (before CPU/human branching)
			all_player_hands[p] = client_hand.duplicate(true)

			if str(gamestate.players[p]).contains("CPU"):
				var double_count = 0
				for d in client_hand:
					if d[0] == d[1]: double_count += 1
					if d[0] < d[1]: d.reverse()

				# Reshuffle if 4+ doubles
				if double_count >= 4:
					dominos.append_array(client_hand)
					dominos.shuffle()
					client_hand.clear()
					for i in range(9):
						var replacement = dominos.pop_front()
						if replacement[0] < replacement[1]: replacement.reverse()
						client_hand.append(replacement)

				cpu_hands[p] = client_hand
				all_player_hands[p] = client_hand.duplicate(true)
			else:
				rpc_id(p, "receive_hand", client_hand)
			
	# Sync the remaining deck to everyone so future mid-game draws work
	rpc("sync_full_deck", dominos)
	
	# Render the host's hand locally
	render_hand(my_hand)

@rpc("any_peer") func receive_hand(hand):
	render_hand(hand)

@rpc("authority", "call_remote") func sync_full_deck(new_deck):
	dominos = new_deck

# Takes an array of dominoes and renders them on screen
func render_hand(drawn_dominos):
	# Ensure the numbers are formatted correctly before sorting
	for i in range(drawn_dominos.size()):
		if drawn_dominos[i][0] < drawn_dominos[i][1]:
			drawn_dominos[i].reverse()
			
	# Sort by lowest number, low to high
	drawn_dominos.sort_custom(func(a, b):
		var min_a = min(a[0], a[1])
		var min_b = min(b[0], b[1])
		if min_a == min_b:
			return max(a[0], a[1]) < max(b[0], b[1])
		return min_a < min_b
	)

	for i in range(drawn_dominos.size()):
		# get domino info
		var domino_nums = drawn_dominos[i]
		var domino = Domino.instantiate()
		var domino_title = str(domino_nums[1]) + str(domino_nums[0])
		domino.get_node("Sprite2D").texture = load(ReferenceManager.get_reference("dominos/" + domino_title + ".png"))
		add_child(domino)

		# set domino position and scale
		var hand_count = drawn_dominos.size()
		var total_width = (hand_count - 1) * HAND_SPACING
		var hand_center_x = -192.0
		domino.position = Vector2(hand_center_x + (i * HAND_SPACING) - (total_width / 2.0), 175)
		domino.scale = HAND_SCALE
		domino.rotation_degrees = 270

		domino.set_base_scale(HAND_SCALE)
		# initialize domino
		domino.init(
			domino_nums[0],
			domino_nums[1],
			curriculum.domino_dict[domino_title][1],
			curriculum.domino_dict[domino_title][0],
			true
		)
	
	# set the hand array to the drawn dominos
	hand_dominos = drawn_dominos

# Rearrange unplaced hand dominoes to fill gaps and stay centered after a placement
func rearrange_hand() -> void:
	var all_nodes = get_tree().get_nodes_in_group("dominos")
	var unplaced: Array = []
	for domino in all_nodes:
		if not domino.placed:
			unplaced.append(domino)
	# Sort left to right by current x-position to preserve ordering
	unplaced.sort_custom(func(a, b): return a.position.x < b.position.x)
	var hand_count: int = unplaced.size()
	if hand_count == 0:
		return
	var total_width: float = (hand_count - 1) * HAND_SPACING
	var hand_center_x: float = -192.0
	for i in range(hand_count):
		var new_pos := Vector2(hand_center_x + (i * HAND_SPACING) - (total_width / 2.0), 175)
		unplaced[i].position = new_pos
		unplaced[i].original_pos = new_pos

# path set-up
func add_position(global_pos: Vector2) -> void:
	position_table.append(global_pos)
	print("add_position(global)=", global_pos, " idx=", position_table.size() - 1)

# take a domino from the main deck
func draw_domino():
	var nums = dominos.pop_front()
	# print("len: ", len(dominos))
	if nums[0] < nums[1]:
		nums.reverse()
	# print(nums, len(dominos))

	# update every player's deck to stay in sync
	rpc("update_deck")
	return nums

func clear_selected_domino():
	if selected_domino:
		selected_domino.deselect()
	selected_domino = null
	_clear_placement_indicators()

func get_selected_domino():
	return selected_domino

# Validate that a given domino is selected or not
func is_domino_selected(domino) -> bool:
	return selected_domino == domino

# Attempt to select domino. Return true if successful.
func select_domino(domino) -> bool:
	# (Fall 2025) added to restrict more than 1 domino being placed a turn if its not a double
	if (can_place == false):
		print("Cannot place anymore this turn") # debug
		return false
		
	if selected_domino == null:
		selected_domino = domino
	if selected_domino == domino:
		_highlight_valid_placements(domino)
		return true
	return false

# update deck from other player's drawing a domino
@rpc("any_peer") func update_deck():
	var _nums = dominos.pop_front()

# handles placing of domino onto a path
func place_domino(num):
	_verify_anchors_ready()
	var flip = false
	if turn != self_num or !selected_domino:
		return
	if num < 6 and num != self_num and not train_open[num]:
		print("Cannot play here. Train is closed!")
		return
	
	# Extraction of the true Top and Bottom domino values to match the visual sprite
	var d_title = str(min(selected_domino.top_num, selected_domino.bottom_num)) + str(max(selected_domino.top_num, selected_domino.bottom_num))
	var elements = curriculum.domino_dict[d_title]
	var true_top = int(d_title[0])
	var true_bot = int(d_title[1])
	var top_el = elements[0]
	var bot_el = elements[1]

	# Check if domino can be placed here
	if true_top == path_ends[num] or true_bot == path_ends[num]:
		print("DOMINO Placed at ", num) 
		
		# CRASH FIX: First domino of the round has no end_dominos[num] yet!
		if end_dominos[num] == null:
			if true_bot != path_ends[num]:
				flip = true
		else:
			if true_bot != path_ends[num] or (true_top == path_ends[num] and top_el != end_dominos[num].top_element):
				flip = true
			
		# Check for alloy
		var touching_el = top_el if flip else bot_el
		if end_dominos[num] != null and end_dominos[num].top_element != touching_el:
			if curriculum.element_to_alloy.has(touching_el):
				var alloy_name = curriculum.element_to_alloy[touching_el]
				rpc("increment_alloys", self_num + 1, alloy_name)
				increment_alloys(self_num + 1, alloy_name)

		# Check for footprint tile
		if true_top == true_bot:
			rpc("increment_footprint_tiles", self_num + 1, center_num, true_top)
			increment_footprint_tiles(self_num + 1, center_num, true_top)

		# Check Wellness Bead
		if num < 6 and num != self_num and train_open[num]:
			increment_wellness_beads(self_num + 1)
			rpc("increment_wellness_beads", self_num + 1)
			display_wellness_prompt()

		# Force the domino to initialize correctly so the texture syncs with math
		selected_domino.init(true_top, true_bot, top_el, bot_el, false)
		if flip:
			selected_domino.get_node("Sprite2D").rotation_degrees = 180
		else:
			selected_domino.get_node("Sprite2D").rotation_degrees = 0

		# Place locally
		selected_domino.mark_as_placed(PLACED_SCALE)
		selected_domino.global_position = _path_position_for_step(num, path_step_count[num])
		_orient_to_path(selected_domino, num)

		# Update path ends
		if flip:
			path_ends[num] = true_bot
			selected_domino.top_element = bot_el # Store outward element for next domino
		else:
			path_ends[num] = true_top
			selected_domino.top_element = top_el

		end_dominos[num] = selected_domino
		path_step_count[num] += 1
		num_placed += 1
		
		if num == self_num and train_open[self_num]:
			rpc("set_train_open", self_num, false)
		
		# Broadcast the exact placement to everyone
		rpc("update_domino_path", [true_bot, true_top], [bot_el, top_el], position_table[num], num, flip)

		hand_dominos.erase([selected_domino.top_num, selected_domino.bottom_num])
		hand_dominos.erase([selected_domino.bottom_num, selected_domino.top_num])
		if multiplayer.is_server():
			# Update host tracking: remove placed domino from local player's tracked hand
			var placed_pair = [selected_domino.top_num, selected_domino.bottom_num]
			if all_player_hands.has(multiplayer.get_unique_id()):
				for i in range(all_player_hands[multiplayer.get_unique_id()].size()):
					var h = all_player_hands[multiplayer.get_unique_id()][i]
					if (h[0] == placed_pair[0] and h[1] == placed_pair[1]) or (h[0] == placed_pair[1] and h[1] == placed_pair[0]):
						all_player_hands[multiplayer.get_unique_id()].remove_at(i)
						break
		rearrange_hand()

		if true_top == true_bot:
			can_place = true
		else:
			can_place = false
			
		clear_selected_domino()
		$Place.playing = true
		
		if not can_place:
			rpc("advance_turn")
			advance_turn()
			can_place = true

@rpc("any_peer", "call_local") func set_train_open(num: int, is_open: bool):
	train_open[num] = is_open
	_update_train_indicator(num, is_open)

# Highlight valid placement paths when a domino is selected.
# Passes category-based color: green for player's own path, gold for sun paths, orange for open trains.
func _highlight_valid_placements(domino) -> void:
	_clear_next_slot_indicators()
	var path_names := ["Path1", "Path2", "Path3", "Path4", "Path5", "Path6", "SunrisePath", "SunsetPath"]
	for i in range(path_names.size()):
		var path_node = get_node_or_null(path_names[i])
		if path_node and path_node.has_method("set_placement_indicator"):
			path_node.rotation = deg_to_rad(PATH_ANGLE_DEGREES[i] + ROTATION_OFFSET_DEG)
			# Check if this domino can be placed on this path
			var can_place_here := false
			if domino.bottom_num == path_ends[i] or domino.top_num == path_ends[i]:
				# Check train access rules
				if i >= 6:  # Sunrise/Sunset -- always accessible
					can_place_here = true
				elif i == self_num:  # Own path -- always accessible
					can_place_here = true
				elif train_open[i]:  # Other player's open train
					can_place_here = true
			# Determine category-based color (green=player, gold=sun, orange=train)
			var indicator_color: Color
			if i >= 6:
				indicator_color = Color(1.0, 0.84, 0.0, 0.8)   # gold for sun paths
			elif i == self_num:
				indicator_color = Color(0.1, 0.9, 0.1, 0.8)    # green for player's own path
			else:
				indicator_color = Color(1.0, 0.5, 0.0, 0.8)    # orange for open trains
			path_node.set_placement_indicator(can_place_here, indicator_color)
			if can_place_here and path_step_count[i] > 0:
				_add_next_slot_indicator(i, indicator_color)

# Clear all placement indicators from all path nodes.
func _clear_placement_indicators() -> void:
	var path_names := ["Path1", "Path2", "Path3", "Path4", "Path5", "Path6", "SunrisePath", "SunsetPath"]
	for path_name in path_names:
		var path_node = get_node_or_null(path_name)
		if path_node and path_node.has_method("clear_indicators"):
			path_node.clear_indicators()
	_clear_next_slot_indicators()

# Spawns a next-slot indicator at the next available step on the given path.
# path_step_count is incremented after each placement, so it already equals the next
# available slot index — no +1 needed.
func _add_next_slot_indicator(path_num: int, color: Color) -> void:
	var next_step: int = path_step_count[path_num]
	var world_pos := _path_position_for_step(path_num, next_step)
	var indicator := _NextSlotIndicator.new(color, path_num)
	# IMPORTANT: add_child BEFORE setting global_position/rotation/scale.
	# Godot only resolves global_position correctly when the node is already in the
	# scene tree. Setting global_position before add_child treats the value as a
	# local position (no parent transform applied), causing the indicator to appear
	# at the wrong location when the parent node has a non-identity transform
	# (e.g., World scale = Vector2(0.5, 0.5)).
	add_child(indicator)
	indicator.global_position = world_pos
	indicator.rotation = deg_to_rad(PATH_ANGLE_DEGREES[path_num] + ROTATION_OFFSET_DEG)
	# Use the same scale as Path nodes (0.03) — NOT PLACED_SCALE (0.08).
	# Both Path._draw() and _NextSlotIndicator._draw() use identical base rect
	# dimensions (half_w=180, half_h=320), so they need matching node scale.
	# PLACED_SCALE is for Domino sprite instances which have different internal sizes.
	indicator.scale = Vector2(0.03, 0.03)
	_next_slot_indicators.append(indicator)

# Cleans up all next-slot indicator nodes.
func _clear_next_slot_indicators() -> void:
	for ind in _next_slot_indicators:
		if is_instance_valid(ind):
			ind.queue_free()
	_next_slot_indicators.clear()

# Update the train indicator on a single path node when its open/closed state changes.
func _update_train_indicator(path_num: int, is_open: bool) -> void:
	var path_names := ["Path1", "Path2", "Path3", "Path4", "Path5", "Path6", "SunrisePath", "SunsetPath"]
	if path_num < 0 or path_num >= path_names.size():
		return
	var path_node = get_node_or_null(path_names[path_num])
	if path_node and path_node.has_method("set_train_indicator"):
		path_node.rotation = deg_to_rad(PATH_ANGLE_DEGREES[path_num] + ROTATION_OFFSET_DEG)
		# Pass category color for train indicator
		var train_color: Color
		if path_num >= 6:
			train_color = Color(1.0, 0.84, 0.0, 0.8)   # gold for sun paths
		else:
			train_color = Color(1.0, 0.5, 0.0, 0.8)     # orange for trains
		path_node.set_train_indicator(is_open, train_color)

# increment total score for player
func increment_total(num):
	var path = "Character Bubble" + str(num) + "/Score/Button/Popup/Lydia_number"
	get_node(path).text = str(int(get_node(path).text) + 1)
	gamestate.lydia_lion[num] = int(get_node(path).text)
	$Acquire.playing = true


# display wellness bead popup
func display_wellness_prompt():
	$WellnessBeadPopup/Title.text = "You Got a..."
	$WellnessBeadPopup/WellnessBead.text = "Wellness Bead!"
	$WellnessBeadPopup/Info.text = "You helped someone on their path and so helped promote community wellness!"
	$WellnessBeadPopup.visible = true


# increment wellness beads for player denoted by num
@rpc("any_peer") func increment_wellness_beads(num):
	var path = "Character Bubble" + str(num) + "/Score/Button/Popup/Wellness_number"
	get_node(path).text = str(int(get_node(path).text) + 1)
	gamestate.wellness_beads[num] = get_node(path).text
	increment_total(num)


# increment alloys earned for player denoted by num
@rpc("any_peer") func increment_alloys(num, alloy):
	var path = "Character Bubble" + str(num) + "/Score/Button/Popup/Alloy_number"
	get_node(path).text = str(int(get_node(path).text) + 1)
	gamestate.alloys[num] = int(get_node(path).text)
	increment_total(num)
	
	$AlloyPopup/Title.text = "Alloy Acquired!"
	$AlloyPopup/Alloy.text = alloy
	$AlloyPopup/Info.text = curriculum.alloy_table[alloy]
	$AlloyPopup.visible = true


# increment footprint tiles earned for player denoted by player_num
@rpc("any_peer") func increment_footprint_tiles(player_num, round_num, footprint_num):
	var path = "Character Bubble" + str(player_num) + "/Score/Button/Popup/Footprint_number"
	get_node(path).text = str(int(get_node(path).text) + 1)
	gamestate.footprint_tiles[player_num] = int(get_node(path).text)
	increment_total(player_num)
	display_footprint_tile(round_num, footprint_num)
	# ensure the tile is visible on the board
	footprint_tile_ring.show_tile(footprint_num, round_num)

func display_footprint_tile(round_num: int, footprint_num: int) -> void:
	var index = FootprintTile.convert_to_index(footprint_num, round_num)
	if round_num < 6:
		$FootprintTilePopup/Title.text = "Footprint Tile Acquired!"
		# TODO: <remove the else block and refactor once all 60 footprint tiles have been reimplemented in curriculum.footprint_tile_table>
		if index < 30: # if one of the tiles reimplemented in footprint_tile_table (the first 30 so far)
			# use the new implementation
			$FootprintTilePopup/FootprintTile.text = curriculum.footprint_tile_table[index][0]
			$FootprintTilePopup/Info.text = ""
			$FootprintTilePopup/Description.text = curriculum.footprint_tile_table[index][1]
		else: # otherwise use the old implementation
			var table_index = str(round_num) + str(footprint_num)
			$FootprintTilePopup/FootprintTile.text = curriculum.footprint_title_table[table_index]
			$FootprintTilePopup/Info.text = curriculum.footprint_text_table[table_index]
			$FootprintTilePopup/Description.text = ""
		$FootprintTilePopup.visible = true

# update domino path for all players after a player places a domino
@rpc("any_peer") func update_domino_path(domino_nums, domino_elms, pos, path_num, flip):
	position_table[path_num] = pos

	# RPC format guarantees index 0 is bot, index 1 is top
	var bot_n = domino_nums[0]
	var top_n = domino_nums[1]
	var bot_e = domino_elms[0]
	var top_e = domino_elms[1]

	var domino = Domino.instantiate()
	add_child(domino)
	domino.scale = PLACED_SCALE
	domino.global_position = _path_position_for_step(path_num, path_step_count[path_num])
	_orient_to_path(domino, path_num)

	var domino_title = str(top_n) + str(bot_n)
	domino.get_node("Sprite2D").texture = load(ReferenceManager.get_reference("dominos/" + domino_title + ".png"))
	domino.init(top_n, bot_n, top_e, bot_e, true)
	domino.mark_as_placed(PLACED_SCALE)

	# Flawless Flip logic
	if flip:
		domino.get_node("Sprite2D").rotation_degrees = 180
		path_ends[path_num] = bot_n
		domino.top_element = bot_e
	else:
		domino.get_node("Sprite2D").rotation_degrees = 0
		path_ends[path_num] = top_n
		domino.top_element = top_e

	end_dominos[path_num] = domino
	path_step_count[path_num] += 1
	_consecutive_help_count = 0
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id != 0 and all_player_hands.has(sender_id):
			# Remove the placed domino from tracked hand using domino_nums [bot, top]
			for i in range(all_player_hands[sender_id].size()):
				var h = all_player_hands[sender_id][i]
				if (h[0] == domino_nums[0] and h[1] == domino_nums[1]) or (h[0] == domino_nums[1] and h[1] == domino_nums[0]):
					all_player_hands[sender_id].remove_at(i)
					break

# replace placed domino with one from the deck
func replace_domino():
	var domino_nums = draw_domino()
	if domino_nums:
		var domino = Domino.instantiate()
		var domino_title = str(domino_nums[1]) + str(domino_nums[0])
		domino.get_node("Sprite2D").texture = load(ReferenceManager.get_reference("dominos/" + domino_title + ".png"))
		add_child(domino)
		domino.position = selected_domino.original_pos
		domino.init(
			domino_nums[0],
			domino_nums[1],
			curriculum.domino_dict[domino_title][1],
			curriculum.domino_dict[domino_title][0],
			true
		)
	else:
		return

# go to next round of play
@rpc("any_peer") func next_round():
	# show all footprint tiles from this round
	footprint_tile_ring.show_round(center_num)
	
	# remove all old dominos from screen
	num_placed = 0
	_consecutive_help_count = 0
	all_player_hands.clear()
	path_step_count = [0, 0, 0, 0, 0, 0, 0, 0]
	var group_dominos = get_tree().get_nodes_in_group("dominos")
	clear_selected_domino()
	for domino in group_dominos:
		domino.queue_free()

	# if we've completed round 9, end game
	if center_num >= 9:
		add_tower(center_num + 1)
		$Turn.text = "Game\nOver!"
		$End.text = "Winner: " + determine_winner() + "\n(Hover over faces to see stats.)"
		$End.visible = true
		$Next.visible = false
		# (Fall 2025) added visibility conditions for created buttons
		$Help.visible = false
		
		# Only show the reset button to the host
		if multiplayer.is_server():
			$Reset.visible = true
		else:
			$Reset.visible = false

		center_num += 1
		return

	# randomize dominos
	dominos = [] + gamestate.dominos
	dominos.shuffle()

	# increment round number
	center_num += 1

	SaveManager.Save["0"].Current_Round += 1

	# add tower
	add_tower(center_num)
	
	# remove center domino from deck
	print(center_num, center_num)
	dominos.erase([center_num, center_num])

	# reset domino paths
	path_ends = []
	for _i in range(8):
		path_ends.append(center_num)
	end_dominos = [null, null, null, null, null, null, null, null]

	# load center domino
	var domino_title = ReferenceManager.get_reference("dominos/" + str(center_num) + str(center_num) + ".png")
	$CentralDomino.get_node("Sprite2D").texture = load(domino_title)
	
	var center_area := $CentralDomino.get_node_or_null("Area2D")
	if center_area:
		center_area.input_pickable = false
		center_area.monitoring = false
	
	# reset path visibility
	for i in range(1, 7):
		if i != self_num + 1:
			var path_node = get_node("Path" + str(i))
			if path_node:
				path_node.visible = true
				print("Found and made visible: Path" + str(i))
			else:
				print("Could not find node: Path" + str(i))
				# Print all child nodes to see what's actually available
				for child in get_children():
					print("Found child node: ", child.name)
	
	# Set a new random player's turn
	randomize_turn()

# Evaluates the CPU's hand and returns the best valid move
func calculate_cpu_move(cpu_id):
	if not cpu_hands.has(cpu_id): return null
	
	var c_hand = cpu_hands[cpu_id]
	var my_path_idx = sorted_players.find(cpu_id)
	
	# Priority 1: Personal Path
	for i in range(c_hand.size()):
		var domino_nums = c_hand[i]
		var d_title = str(min(domino_nums[0], domino_nums[1])) + str(max(domino_nums[0], domino_nums[1]))
		
		if domino_nums[0] == path_ends[my_path_idx] or domino_nums[1] == path_ends[my_path_idx]:
			return {"hand_idx": i, "path_idx": my_path_idx, "nums": domino_nums, "title": d_title}

	# Priority 2: Help others if personal path is blocked
	for i in range(c_hand.size()):
		var domino_nums = c_hand[i]
		var d_title = str(min(domino_nums[0], domino_nums[1])) + str(max(domino_nums[0], domino_nums[1]))
		
		for p_idx in range(6):
			if p_idx != my_path_idx and train_open[p_idx]:
				if domino_nums[0] == path_ends[p_idx] or domino_nums[1] == path_ends[p_idx]:
					return {"hand_idx": i, "path_idx": p_idx, "nums": domino_nums, "title": d_title}
					
	# Priority 3: Sun Paths
	for i in range(c_hand.size()):
		var domino_nums = c_hand[i]
		var d_title = str(min(domino_nums[0], domino_nums[1])) + str(max(domino_nums[0], domino_nums[1]))
		
		for sun_idx in [6, 7]:
			if domino_nums[0] == path_ends[sun_idx] or domino_nums[1] == path_ends[sun_idx]:
				return {"hand_idx": i, "path_idx": sun_idx, "nums": domino_nums, "title": d_title}
					
	return null

# True stalemate check: returns true if NO player has ANY valid move on ANY accessible path
# Called on host only. Per D-09, reuses calculate_cpu_move matching logic.
func _check_stalemate() -> bool:
	if not multiplayer.is_server():
		return false
	for idx in range(sorted_players.size()):
		var pid = sorted_players[idx]
		var player_hand = []
		if all_player_hands.has(pid):
			player_hand = all_player_hands[pid]
		elif cpu_hands.has(pid):
			player_hand = cpu_hands[pid]
		else:
			return false  # Unknown hand, assume not stuck
		if player_hand.size() == 0:
			continue  # No dominos left, can't move but not blocking
		for domino_pair in player_hand:
			# Check personal path
			if domino_pair[0] == path_ends[idx] or domino_pair[1] == path_ends[idx]:
				return false
			# Check open trains (other player paths)
			for p_idx in range(6):
				if p_idx != idx and train_open[p_idx]:
					if domino_pair[0] == path_ends[p_idx] or domino_pair[1] == path_ends[p_idx]:
						return false
			# Check sun paths (indices 6 and 7)
			for sun_idx in [6, 7]:
				if domino_pair[0] == path_ends[sun_idx] or domino_pair[1] == path_ends[sun_idx]:
					return false
	return true

func _trigger_stalemate() -> void:
	if not multiplayer.is_server():
		return
	rpc("show_stalemate_popup")

@rpc("authority", "call_local") func show_stalemate_popup():
	$StalematePopup.visible = true
	await get_tree().create_timer(3.0).timeout
	$StalematePopup.visible = false
	# All peers call next_round() locally — show_stalemate_popup already runs on
	# all peers via @rpc("authority", "call_local"), so no additional rpc_id calls needed.
	# Host-only code inside next_round() (like setup_dominos) is already guarded
	# by multiplayer.is_server().
	next_round()
	if multiplayer.is_server() and center_num <= 9:
		setup_dominos()

@rpc("any_peer") func sync_turn(new_turn):
	turn = new_turn
	_update_turn_label()

@rpc("any_peer") func advance_turn():
	turn = (turn + 1) % len(gamestate.players)
	_update_turn_label()
	if multiplayer.is_server() and _check_stalemate():
		_trigger_stalemate()

func _update_turn_label():
	var current_player_id = sorted_players[turn]
	var current_name = gamestate.players[current_player_id]
	
	$Turn.text = current_name + "'s\nTurn"
	# Only show the "Need Help" button if it is currently YOUR turn
	$Help.visible = (turn == self_num)
	
	# CPU TURN AUTOMATION (HOST ONLY)
	if str(current_name).contains("CPU") and multiplayer.is_server():
		_execute_cpu_turn_async(current_player_id)

# The async function handles the CPU playing the domino
func _execute_cpu_turn_async(cpu_id):
	await get_tree().create_timer(1.5).timeout 
	if sorted_players[turn] != cpu_id: return 
	
	var move = calculate_cpu_move(cpu_id)
	var my_path_idx = sorted_players.find(cpu_id)
	
	if move != null:
		var elements = curriculum.domino_dict[move.title]
		var flip = false
		
		var true_top = int(move.title[0])
		var true_bot = int(move.title[1])
		var top_e = elements[0]
		var bot_e = elements[1]
		
		# CRASH FIX: First piece of the round
		if end_dominos[move.path_idx] == null:
			if true_bot != path_ends[move.path_idx]:
				flip = true
		else:
			if true_bot != path_ends[move.path_idx] or (true_top == path_ends[move.path_idx] and top_e != end_dominos[move.path_idx].top_element):
				flip = true

		# CPU SCORING & POPUP CHECKS
		var touching_el = top_e if flip else bot_e
		if end_dominos[move.path_idx] != null and end_dominos[move.path_idx].top_element != touching_el:
			if curriculum.element_to_alloy.has(touching_el):
				var alloy_name = curriculum.element_to_alloy[touching_el]
				rpc("increment_alloys", my_path_idx + 1, alloy_name)
				increment_alloys(my_path_idx + 1, alloy_name)
			
		if true_top == true_bot:
			rpc("increment_footprint_tiles", my_path_idx + 1, center_num, true_top)
			increment_footprint_tiles(my_path_idx + 1, center_num, true_top)
			
		if move.path_idx < 6 and move.path_idx != my_path_idx and train_open[move.path_idx]:
			rpc("increment_wellness_beads", my_path_idx + 1)
			increment_wellness_beads(my_path_idx + 1)
			display_wellness_prompt()
			
		cpu_hands[cpu_id].remove_at(move.hand_idx)
		if all_player_hands.has(cpu_id):
			all_player_hands[cpu_id].remove_at(move.hand_idx)

		if move.path_idx == my_path_idx and train_open[my_path_idx]:
			rpc("set_train_open", my_path_idx, false)
			set_train_open(my_path_idx, false)
			
		rpc("update_domino_path", [true_bot, true_top], [bot_e, top_e], position_table[move.path_idx], move.path_idx, flip)
		update_domino_path([true_bot, true_top], [bot_e, top_e], position_table[move.path_idx], move.path_idx, flip)
		
		# POPUP PAUSE LOGIC
		while $AlloyPopup.visible or $FootprintTilePopup.visible or $WellnessBeadPopup.visible:
			await get_tree().process_frame
		
		if true_top == true_bot:
			_execute_cpu_turn_async(cpu_id)
		else:
			rpc("advance_turn")
			advance_turn()
	else:
		rpc("set_train_open", my_path_idx, true)
		set_train_open(my_path_idx, true)
		rpc("advance_turn")
		advance_turn()

# handle when next round button pressed by host
func _on_Next_pressed() -> void:
	# reset field for host
	next_round()
	can_place = true
	$Help.visible = false

	# reset field for everyone else
	for p in gamestate.players:
		if p != 1:
			rpc_id(p, "next_round")

	# get new dominos from deck
	if center_num <= 9:
		setup_dominos()
		SFXController.playSFX(ReferenceManager.get_reference("next.wav"))

func _on_Reset_pressed() -> void:
	if multiplayer.is_server():
		# Broadcast the reset command to all peers
		rpc("sync_reset_game")

@rpc("authority", "call_local") func sync_reset_game():
	get_tree().reload_current_scene()

#intialize tower as not seen
func intialize_tower():
	$Tower/Sprite2D/Energy.visible = false
	$Tower/Sprite2D/Stability.visible = false
	$Tower/Sprite2D/Prepared_Enviroment.visible = false
	$Tower/Sprite2D/Ability.visible = false
	$Tower/Sprite2D/Responsibility.visible = false
	$Tower/Sprite2D/Perception.visible = false
	$Tower/Sprite2D/Resilience.visible = false
	$Tower/Sprite2D/Relationship.visible = false
	$Tower/Sprite2D/Discernment.visible = false
	$Tower/Sprite2D/Arts.visible = false
	$Tower/Sprite2D/Sciences.visible = false
	$Tower/Sprite2D/Humanities.visible = false
	$Tower/Sprite2D/Diamond.visible = false

# Display tower
func add_tower(round_num):
	if round_num == 6:
		$Tower/Sprite2D/Energy.visible = true
		$Tower/Sprite2D/Stability.visible = true
		$Tower/Sprite2D/Prepared_Enviroment.visible = true
	elif round_num == 7:
		$Tower/Sprite2D/Ability.visible = true
		$Tower/Sprite2D/Responsibility.visible = true
		$Tower/Sprite2D/Perception.visible = true
	elif round_num == 8:
		$Tower/Sprite2D/Resilience.visible = true
		$Tower/Sprite2D/Relationship.visible = true
		$Tower/Sprite2D/Discernment.visible = true
	elif round_num == 9:
		$Tower/Sprite2D/Arts.visible = true
		$Tower/Sprite2D/Sciences.visible = true
		$Tower/Sprite2D/Humanities.visible = true
	elif round_num == 10:
		$Tower/Sprite2D/Diamond.visible = true

func _on_Help_pressed() -> void:
	if turn == self_num:
		rpc("set_train_open", self_num, true)
		rpc("advance_turn")
		advance_turn()
		can_place = true
		SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
		_consecutive_help_count += 1
		if multiplayer.is_server() and _consecutive_help_count >= len(sorted_players):
			_trigger_stalemate()
			return

@rpc("any_peer") func add_path(num):
	var path_node = get_node_or_null("Path" + str(num))
	if path_node:
		path_node.visible = true

@rpc("any_peer") func remove_path(num):
	var path_node = get_node_or_null("Path" + str(num))
	if path_node and "temp" in path_node and path_node.temp:
		path_node.visible = false

func _close_WellnessBead_popup() -> void:
	$WellnessBeadPopup.visible = false

func _close_Alloy_popup() -> void:
	$AlloyPopup.visible = false

func _close_FootprintTile_popup():
	$FootprintTilePopup.visible = false
	
# return winner's name (could also be names depending on ties) based on highest total points
func determine_winner():
	var best_score = -1
	var winners = []
	for i in range(1, len(sorted_players) + 1):
		var current_player = get_node("Character Bubble" + str(i) + "/Score/Button/Popup")
		if int(current_player.get_node("Lydia_number").text) > best_score:
			winners = [current_player.get_node("Name_text").text]
			best_score = int(current_player.get_node("Lydia_number").text)
		elif int(current_player.get_node("Lydia_number").text) == best_score:
			winners.append(current_player.get_node("Name_text").text)
	var winner_text = ""
	for winner in winners:
		winner_text += winner
		winner_text += ", "
	winner_text.erase(winner_text.length() - 1, 1)
	winner_text.erase(winner_text.length() - 1, 1)
	return winner_text

func _on_Code_pressed():
	$EnterCodeMenu.visible = true
	$EnterCodeMenu/InvalidCode.visible = false
	$EnterCodeMenu/UsedCode.visible = false
	$EnterCodeMenu/AcceptCode.visible = false
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))

func _on_X_pressed():
	$EnterCodeMenu.visible = false
	$EnterCodeMenu/InvalidCode.visible = false
	$EnterCodeMenu/UsedCode.visible = false
	$EnterCodeMenu/AcceptCode.visible = false
	SFXController.playSFX(ReferenceManager.get_reference("back.wav"))

func _on_EnterButton_pressed():
	var i = 0
	var wrongFlag = true
	$EnterCodeMenu/InvalidCode.visible = false
	$EnterCodeMenu/UsedCode.visible = false
	$EnterCodeMenu/AcceptCode.visible = false
	#print($CodeEnterParent/TextEdit.text)
	for word in usedBonus:
		if ($EnterCodeMenu/MarginContainer/VBoxContainer/NinePatchRect/MarginContainer/LineEdit.text == word):
			$EnterCodeMenu/UsedCode.visible = true
			wrongFlag = false
	for word in bonusWords:
		if ($EnterCodeMenu/MarginContainer/VBoxContainer/NinePatchRect/MarginContainer/LineEdit.text == word):
			$EnterCodeMenu/AcceptCode.visible = true
			increment_total(self_num + 1)
			bonusWords.remove(i)
			usedBonus.append(word)
			wrongFlag = false
		i = i + 1
	if (wrongFlag == true):
		$EnterCodeMenu/InvalidCode.visible = true
		SFXController.playSFX(ReferenceManager.get_reference("back.wav"))

# Updated button UI
# 4/18/2024
var green = Color("74cc4c")
var grey = Color("aaaaaa")

#### VVVV BUTTON HOVER HANDLERS VVVV ####

# Set label color to green when mouse enters texture button.
# Set label color back to grey when mouse leaves.

func _on_EnterCode_mouse_entered():
	$Code/MarginContainer/Label.set("theme_override_colors/font_color", green)
func _on_EnterCode_mouse_exited():
	$Code/MarginContainer/Label.set("theme_override_colors/font_color", grey)

func _on_Next_mouse_entered():
	$Next/MarginContainer/Label.set("theme_override_colors/font_color", green)
func _on_Next_mouse_exited():
	$Next/MarginContainer/Label.set("theme_override_colors/font_color", grey)

func _on_Help_mouse_entered():
	$Help/MarginContainer/Label.set("theme_override_colors/font_color", green)
func _on_Help_mouse_exited():
	$Help/MarginContainer/Label.set("theme_override_colors/font_color", grey)
	
func _on_Reset_mouse_entered():
	$Reset/MarginContainer/Label.set("theme_override_colors/font_color", green)
func _on_Reset_mouse_exited():
	$Reset/MarginContainer/Label.set("theme_override_colors/font_color", grey)

func _on_Start_mouse_entered():
	$Start/MarginContainer/Label.set("theme_override_colors/font_color", green)
func _on_Start_mouse_exited():
	$Start/MarginContainer/Label.set("theme_override_colors/font_color", grey)
	
#### ^^^^ END BUTTON HOVER HANDLERS ^^^^ ####


func _on_HelpButton_pressed():
	$HelpMenu/HelpImage.visible = true
	$HelpMenu.move_to_front()

func _on_CloseButton_pressed():
	$HelpMenu/HelpImage.visible = false
	
	
# functions to fix domino alignment 10/1/2025

func _deg_to_vec2(angle_deg: float) -> Vector2:
	var a := deg_to_rad(angle_deg)
	return Vector2(cos(a), sin(a))

func _path_step_vector(path_num: int) -> Vector2:
	var v := _deg_to_vec2(PATH_ANGLE_DEGREES[path_num])
	return v * STEP_PIXELS

func _path_position_for_step(path_num: int, step_index: int) -> Vector2:
	# Treat stored anchors as LOCAL positions in this DominoWorld
	var local_anchor: Vector2 = position_table[path_num]
	var step: Vector2 = _path_step_vector(path_num)
	var local_pos: Vector2 = local_anchor + step * float(step_index)

	# Convert that local position into global space for placement
	return to_global(local_pos)

# Optional: make the domino visually point along its growth direction
func _orient_to_path(domino: Node2D, path_num: int) -> void:
	domino.rotation = deg_to_rad(PATH_ANGLE_DEGREES[path_num] + ROTATION_OFFSET_DEG)

func _verify_anchors_ready():
	if position_table.size() != 8:
		push_error("Expected 8 anchors, have %s" % position_table.size())

func set_anchor(path_index: int, global_pos: Vector2) -> void:
	if path_index < 0 or path_index >= position_table.size():
		push_error("set_anchor: index out of range: %s" % path_index)
		return
	position_table[path_index] = global_pos
	# Optional debug:
	# print("Anchor[", path_index, "] = ", global_pos)

# Inner class: animated outline shown at the next available slot on a valid path.
# Renders at 0.85x the standard placed-domino footprint to signal "future/preview".
# Clicking the indicator calls place_domino(path_num) on the parent DominoWorld.
class _NextSlotIndicator extends Node2D:
	var _color: Color
	var _path_num: int
	var _glow_time := 0.0

	func _init(color: Color, path_num: int) -> void:
		_color = color
		_path_num = path_num

	func _ready() -> void:
		# Add an Area2D with a RectangleShape2D so mouse clicks are detected.
		# The rect matches the drawn outline (0.85x of the standard 180x320 half-dims).
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		# half_w=153, half_h=272 in local coords; size is full extents.
		rect_shape.size = Vector2(180.0 * 0.85 * 2.0, 320.0 * 0.85 * 2.0)
		shape.shape = rect_shape
		area.add_child(shape)
		add_child(area)
		area.input_event.connect(_on_area_input_event)

	func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_parent().place_domino(_path_num)

	func _process(delta: float) -> void:
		_glow_time += delta
		queue_redraw()

	func _draw() -> void:
		# Slightly smaller than Path.gd indicator (0.85x) to signal "preview/future"
		var scale_factor := 0.85
		var half_w := 180.0 * scale_factor
		var half_h := 320.0 * scale_factor
		var rect := Rect2(-half_w, -half_h, half_w * 2.0, half_h * 2.0)
		var glow_alpha := 0.2 + 0.15 * sin(_glow_time * 3.0)
		var glow_color := Color(_color.r, _color.g, _color.b, glow_alpha)
		var line_width := 35.0
		draw_rect(rect, glow_color, false, line_width + 20.0)
		draw_rect(rect, Color(_color.r, _color.g, _color.b, 0.5), false, line_width)
