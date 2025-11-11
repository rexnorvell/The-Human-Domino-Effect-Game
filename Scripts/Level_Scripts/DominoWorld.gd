# domino level scene
class_name DominoWorld
extends Node2D

const HAND_SCALE = Vector2(0.22, 0.22)
const PLACED_SCALE = Vector2(0.08, 0.08)
const ROTATION_OFFSET_DEG := 90.0 # rotate pieces 90° clockwise

# --- Hardcoded step directions by path, in degrees ---
# Order requested: Path1, Path2, Path3?, Path4, Path5, Path6, ?, SunsetPath
const PATH_ANGLE_DEGREES := [292.5, 247.5, 337.5, 157.5, 112.5, 67.5, 202.5, 22.5]

# How far to move each successive domino along that direction
const STEP_PIXELS := 24.0 # tune for your art scale

# Keep a per-path step count; replaces placed_domino_offset
var path_step_count := [0, 0, 0, 0, 0, 0, 0, 0]

@export var Domino: PackedScene
# NOTE: If domino game performance is low, try switching to preload
#const FootprintTile = preload("res://Scripts/FootprintTile.gd")
var FootprintTile = load(ReferenceManager.get_reference("FootprintTile.gd"))
var footprint_tile_ring = null
# NOTE: If domino game performance is low, try switching to preload
#const tower = preload("res://Scripts/Tower.gd")
var tower = load(ReferenceManager.get_reference("Tower.gd"))
var sorted_players = []

var turn = 0 # whose turn is it, indexed from 0 on
var hand = []
var dominos = [] + gamestate.dominos
var self_num = 0 # player's number, indexed from 1 on
var selected_domino = null # currently selected domino
var center_num = 0 # current round number
var num_placed = 0

# Fall 2025
var can_place = true # to check if currently selected domino is a double
var hand_dominos = [] # track dominos in hand
var needs_help = false # track if player needs help

var path_ends = [0, 0, 0, 0, 0, 0, 0, 0] # last number on domino chain in each path
var end_dominos = [null, null, null, null, null, null, null, null] # last domino on domino chain in each path

var position_table: Array[Vector2] = []
var prev_domino_size = 0

var bonusWords = ["Bonus", "Bonus2"]
var usedBonus = ["ABC123"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Next.visible = false
	$NextTurn.visible = false
	$Help.visible = false
	intialize_tower()
	_init_players()
	dominos.erase([0, 0])
	
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
			all_icon_names.append(key.get_slice("/", 1))
	all_icon_names.sort()

	# Reserve local player's chosen icon (fallback to basket.png)
	var my_icon_name: String = gamestate.player_icon.get(multiplayer.get_unique_id(), "basket.png")
	var remaining_icon_pool: Array = all_icon_names.duplicate()
	remaining_icon_pool.erase(my_icon_name)

	# Deterministic per-player icon assignment map to avoid randomness differences across peers
	var assigned_icons := {}

	var ind := 1

	for player_id in sorted_players:
		var bubble_path := "Character Bubble" + str(ind)
		print("\n--- setting up ", bubble_path, " for player_id=", player_id, " ---")

		# Resolve icon filename for this player
		var icon_name: String = ""
		if assigned_icons.has(player_id):
			icon_name = assigned_icons[player_id]
		else:
			var existing_choice: String = gamestate.player_icon.get(player_id, "")
			if existing_choice != "" and existing_choice != "basket.png" and all_icon_names.has(existing_choice):
				# Respect any explicit choice if present and available
				icon_name = existing_choice
				remaining_icon_pool.erase(existing_choice)
			elif player_id == multiplayer.get_unique_id():
				icon_name = my_icon_name
			else:
				# Assign deterministically from remaining pool
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
			"/clothes",
			"/Score/Button/Popup/front_hair",
			"/Score/Button/Popup/back_hair",
			"/Score/Button/Popup/body",
			"/Score/Button/Popup/clothes"
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

	MusicController.playMusic(ReferenceManager.get_reference("main.ogg"))
	print("Started music")

	# Host sees Start button
	if multiplayer.get_unique_id() == 1:
		$Start.visible = true
		print("Host detected, Start button visible")

	$Turn.text = gamestate.players[1] + "'s\nTurn"
	print("Turn label set to ", $Turn.text)
	print("=== _init_players() END ===")


func _on_Start_pressed() -> void:
	if (SaveManager.loaded_data):
		for i in range(0, SaveManager.Save["0"].Current_Round):
			next_round()
	else:
		SaveManager.Save["0"].Current_Round = 0
	setup_dominos()
	
	$Start.queue_free()
	if (self_num == 0):
		$Next.visible = true
		$NextTurn.visible = true
		
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	
	# Fall 2025
	_help_Flag()

# initialize everyone's dominos
func setup_dominos():
	# host domino set up
	draw_7()

	# tell everyone else to draw 7 dominos, in turn
	for p in gamestate.players:
		if p != 1:
			rpc_id(p, "get_starting_hand")


@rpc("any_peer") func get_starting_hand():
	draw_7()


# initialize 7 dominos from main deck on player's screen
func draw_7():
	# draw 7 dominos
	# sort by lowest number, low to high
	var drawn_dominos = []

	for i in range(7):
		var nums = draw_domino()
		drawn_dominos.append(nums)
	
	drawn_dominos.sort_custom(func(a, b):
		var min_a = min(a[0], a[1])
		var min_b = min(b[0], b[1])
		if min_a == min_b:
			return max(a[0], a[1]) < max(b[0], b[1])
		return min_a < min_b
	)

	for i in range(7):
		# get domino info
		var domino_nums = drawn_dominos[i]
		var domino = Domino.instantiate()
		var domino_title = str(domino_nums[1]) + str(domino_nums[0])
		domino.get_node("Sprite2D").texture = load(ReferenceManager.get_reference("dominos/" + domino_title + ".png"))
		add_child(domino)

		# set domino position and scale
		# placed at bottom of screen, with spacing
		# rotate 90 degrees counter-clockwise to lie flat
		var domino_spacing = 85
		domino.position = Vector2((i * domino_spacing) - (192 + domino_spacing * 3), 175)
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
	
	# Fall 2025, set the hand array to the drawn dominos
	hand_dominos = drawn_dominos

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

func get_selected_domino():
	return selected_domino

# Validate that a given domino is selected or not
func is_domino_selected(domino) -> bool:
	return selected_domino == domino

# Attempt to select domino. Return true if successful.
func select_domino(domino) -> bool:
	# if statement added to restrict more than 1 domino being placed a turn if its not a double Fall 2025
	if (can_place == false):
		print("Cannot place anymore this turn")
		return false
		
	if selected_domino == null:
		selected_domino = domino
	return selected_domino == domino

# update deck from other player's drawing a domino
@rpc("any_peer") func update_deck():
	var _nums = dominos.pop_front()

# handles placing of domino onto a path
func place_domino(num):
	print("DOMINO Placed at ", num)
	_verify_anchors_ready()
	var flip = false
	# check if it is your turn and you have selected a domino
	if turn == self_num and selected_domino:
		# check if domino can be placed here
		if (
			selected_domino.bottom_num == path_ends[num]
			or selected_domino.top_num == path_ends[num]
		):
			# flip domino if the top number matches instead of the bottom
			# or if flipping could create an alloy (top number matches but
			# element doesn't)
			if (
				selected_domino.bottom_num != path_ends[num]
				or (selected_domino.top_num == path_ends[num]
				and selected_domino.top_element != end_dominos[num].top_element)
			):
				selected_domino.init(
					selected_domino.top_num,
					selected_domino.bottom_num,
					selected_domino.top_element,
					selected_domino.bottom_element,
					false
				)
				selected_domino.get_node("Sprite2D").rotation_degrees = 180
				flip = true
			# check for alloy
			if end_dominos[num] and end_dominos[num].top_element != selected_domino.bottom_element:
				rpc(
					"increment_alloys",
					self_num + 1,
					curriculum.element_to_alloy[selected_domino.bottom_element]
				)
				increment_alloys(
					self_num + 1, curriculum.element_to_alloy[selected_domino.bottom_element]
				)

			# check for footprint tile
			if selected_domino.top_num == selected_domino.bottom_num:
				rpc(
					"increment_footprint_tiles",
					self_num + 1,
					center_num,
					selected_domino.bottom_num
				)
				increment_footprint_tiles(
					self_num + 1,
					center_num,
					selected_domino.bottom_num
				)

			# remove old domino on path if there was one
			#if end_dominos[num]:
			#	end_dominos[num].queue_free()

			# place domino; update screen and update turn

			# Place locally
			# selected_domino.placed = true
			# selected_domino.scale  = PLACED_SCALE
			selected_domino.mark_as_placed(PLACED_SCALE)

			# If your anchors are GLOBAL positions:
			selected_domino.global_position = _path_position_for_step(num, path_step_count[num])
			# If your anchors are LOCAL to this node, use this instead:
			# selected_domino.position = _path_position_for_step(num, path_step_count[num])

			# Optional facing
			_orient_to_path(selected_domino, num)

			path_ends[num] = selected_domino.top_num
			end_dominos[num] = selected_domino

			# Advance step AFTER using the current slot
			path_step_count[num] += 1
			num_placed += 1
			
			# logic to check if the placed domino is a double, if it was then set the condition Fall 2025
			if (selected_domino.top_num == selected_domino.bottom_num):
				can_place = true
			else:
				can_place = false
			#print(can_place)

			turn = (turn + 1) % len(gamestate.players)
			$Turn.text = gamestate.players[sorted_players[turn]] + "'s\nTurn"

			# if helped another player on their path, get a wellness bead
			var path_node = get_node_or_null("Path2D" + str(num + 1))
			if num < 6 and (path_node and path_node.temp == true):
				increment_wellness_beads(self_num + 1)
				rpc("increment_wellness_beads", self_num + 1)
				display_wellness_prompt()

				# remove the other player's path now that they have been helped
				rpc("remove_path", num + 1)
				remove_path(num + 1)

			# remove one's one path from others if no longer need help
			if num < 6:
				rpc("remove_path", num + 1)

			# update other player screens
			rpc(
				"update_domino_path",
				[selected_domino.bottom_num, selected_domino.top_num],
				[selected_domino.bottom_element, selected_domino.top_element],
				position_table[num],
				num,
				flip
			)

			# get new domino from deck
			# replace_domino()                   # UNCOMMENT IF WANT TO REPLACE DOMINOS
			
			# Fall 2025 logic for when the player needs help, track the currently placed domino
			var placed_domino = []
			# flip how the domino tuple is stored in the hand array based on orientation
			if (flip):
				placed_domino = [selected_domino.top_num, selected_domino.bottom_num]
			else:
				placed_domino = [selected_domino.bottom_num, selected_domino.top_num]
				
			print("Placed domino: ", placed_domino)
			hand_dominos.erase(placed_domino) # remove the domino from the hand array
			
			clear_selected_domino()
			$Place.playing = true
			
		
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
	# Sync our anchor for this path in case host moved it
	position_table[path_num] = pos # (pos should be global anchor)

	var domino = Domino.instantiate()
	add_child(domino)
	domino.scale = PLACED_SCALE

	# If anchors are global:
	domino.global_position = _path_position_for_step(path_num, path_step_count[path_num])
	# If anchors are local, use:
	# domino.position = _path_position_for_step(path_num, path_step_count[path_num])

	# Optional facing
	_orient_to_path(domino, path_num)

	var domino_title = str(min(domino_nums[0], domino_nums[1])) + str(max(domino_nums[0], domino_nums[1]))
	domino.get_node("Sprite2D").texture = load(ReferenceManager.get_reference("dominos/" + domino_title + ".png"))
	domino.init(domino_nums[0], domino_nums[1], domino_elms[0], domino_elms[1], true)
	domino.mark_as_placed(PLACED_SCALE)

	if flip:
		domino.get_node("Sprite2D").rotation_degrees = 180

	path_ends[path_num] = domino_nums[1]
	end_dominos[path_num] = domino

	# Advance step AFTER placing (locks peers to host)
	path_step_count[path_num] += 1

	turn = (turn + 1) % len(gamestate.players)
	$Turn.text = gamestate.players[sorted_players[turn]] + "'s\nTurn"

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
	
	# Fall 2025
	_help_Flag()

# new function added for next turn Fall 2025 
func _on_NextTurn_pressed() -> void:
	print("Next turn")
	print(hand_dominos)
	
	# if all dominos have been exhausted then call next_round (TEMP)
	if hand_dominos.is_empty():
		next_round()
		
	can_place = true
	_help_Flag()
					
# use current dominos to check if you have a playable domino by comparing to all end dominos
func _help_Check() -> bool:
	for end_domino in path_ends:
		for domino in hand_dominos:
			if domino.has(end_domino):
				print("Value of the domino to play on: ", end_domino)
				print("This is a playable domino: ", domino)
				return true
	return false # false when there are no playable dominos

# called whenever help needs to be checked, ie at the start of the game, next turn, or next round
func _help_Flag() -> void:
	if !_help_Check():
		print("Player needs help!")
		$Help.visible = true
		needs_help = true
	
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

# if player cannot play a domino on their paths
func _on_Help_pressed() -> void:
	if turn == self_num:
		# add their path to everyone else's screen
		rpc("add_path", self_num + 1)
		# change turn
		turn = (turn + 1) % len(gamestate.players)
		$Turn.text = gamestate.players[sorted_players[turn]] + "'s\nTurn"
		SFXController.playSFX(ReferenceManager.get_reference("next.wav"))

# add player's path denoted by num to all player's screens
@rpc("any_peer") func add_path(num):
	turn = (turn + 1) % len(gamestate.players)
	$Turn.text = gamestate.players[sorted_players[turn]] + "'s\nTurn"
	get_node("Path2D" + str(num)).visible = true

# remove player's path denoted by num from all player's screens
@rpc("any_peer") func remove_path(num):
	if get_node("Path2D" + str(num)).temp:
		get_node("Path2D" + str(num)).visible = false

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

# added color on hover for added next turn button Fall 2025
func _on_NextTurn_mouse_entered():
	$Next/MarginContainer/Label.set("theme_override_colors/font_color", green)
func _on_NextTurn_mouse_exited():
	$Next/MarginContainer/Label.set("theme_override_colors/font_color", grey)

func _on_Help_mouse_entered():
	$Help/MarginContainer/Label.set("theme_override_colors/font_color", green)
func _on_Help_mouse_exited():
	$Help/MarginContainer/Label.set("theme_override_colors/font_color", grey)

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
