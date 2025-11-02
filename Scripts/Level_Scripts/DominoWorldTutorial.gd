# domino level scene
class_name DominoWorldTutorial
extends Node2D

@export var Domino: PackedScene
# NOTE: If domino game performance is low, try switching to preload
#const FootprintTile = preload("res://Scripts/FootprintTile.gd")
var FootprintTile = load(ReferenceManager.get_reference("FootprintTile.gd"))
var footprint_tile_ring = null
# NOTE: If domino game performance is low, try switching to preload
#const tower = preload("res://Scripts/Tower.gd")
var tower = load(ReferenceManager.get_reference("Tower.gd"))
var sorted_players = []

var turn = 0  # whose turn is it, indexed from 0 on
var hand = []
var dominos = [] + gamestate.dominos
var self_num = 0  # player's number, indexed from 1 on
var selected_domino = null  # currently selected domino
var center_num = 0  # current round number
var num_placed = 0

var path_ends = [0, 0, 0, 0, 0, 0, 0, 0]  # last number on domino chain in each path
var end_dominos = [null, null, null, null, null, null, null, null]  # last domino on domino chain in each path

var position_table = []
var placed_domino_offset = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), 
							Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), 
							Vector2(0, 0), Vector2(0, 0)]
var prev_domino_size = 0

var bonusWords = ["Bonus", "Bonus2"]
var usedBonus = ["ABC123"]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("CHECK")
	$Next.visible = false
	intialize_tower()
	_init_players()
	dominos.erase([0, 0])
	
#  Sets up and resolves players and their resulting nodes
func _init_players() -> void:
	# initialize footprint tile ring
	# NOTE: If domino game performance is low, try switching to preload
	#footprint_tile_ring = preload("res://Scripts/FootprintTileRing.gd").new(self)
	footprint_tile_ring = load(ReferenceManager.get_reference("FootprintTileRing.gd")).new(self)
	footprint_tile_ring.position = $Board.position
	add_child(footprint_tile_ring)
	
	# intialize character bubble icons around table
	var ind = 1

	for p in gamestate.players:
		sorted_players.append(p)
	sorted_players.sort()
	# setup each player one by one
	for player_id in sorted_players:
		# initialize player icon for board view
		var current = "Character Bubble" + str(ind)
		var icon_name = gamestate.player_icon.get(player_id, "basket.png")
		var icon_texture = load(ReferenceManager.get_reference("player_icons/" + icon_name))
		
		# Set player icon on the face node (main board view)
		get_node(current + "/face").set_texture(icon_texture)
		
		# Hide hair sprites since we're using player icons
		get_node(current + "/front_hair").visible = false
		get_node(current + "/back_hair").visible = false
		
		# initialize player icon in popup
		get_node(current + "/Score/Button/Popup/front_hair").set_texture(icon_texture)
		get_node(current + "/Score/Button/Popup/back_hair").visible = false
		get_node(current + "/Score/Button/Popup/body").set_texture(icon_texture)
		get_node(current + "/Score/Button/Popup/clothes").visible = false
		get_node(current + "/Score/Button/Popup/Name_text").set_text(
			gamestate.players[player_id]
		)

		# initalize elcitraps
		for i in range(len(gamestate.elcitraps[player_id])):
			get_node(current + "/Score/Button/Popup/elcitrap" + str(i)).init(
				(gamestate.elcitraps[player_id])[i]
			)

		# initalize loaded scores if data is loaded
		if(SaveManager.loaded_data):
			var path = current + "/Score/Button/Popup/"
			print(gamestate.lydia_lion.keys().find(player_id))
			if(gamestate.lydia_lion.keys().find(player_id) == -1):
				get_node(path + "Lydia_number").text == "0"
			else:
				get_node(path + "Lydia_number").text = str(gamestate.lydia_lion[player_id])
			if(gamestate.wellness_beads.keys().find(player_id) == -1):
				get_node(path + "Wellness_number").text == "0"
			else:
				get_node(path + "Wellness_number").text = str(gamestate.wellness_beads[player_id])
			if(gamestate.alloys.keys().find(player_id) == -1):
				get_node(path + "Alloy_number").text = "0"
			else:
				get_node(path + "Alloy_number").text = str(gamestate.alloys[player_id])
			if(gamestate.footprint_tiles.keys().find(player_id) == -1):
				get_node(path + "Footprint_number").text = "0"
			else:
				get_node(path + "Footprint_number").text = str(gamestate.footprint_tiles[player_id])
		# set self number and make own path bubble visible
		if player_id == get_tree().get_unique_id():
			self_num = ind - 1
			get_node("Path3D" + str(ind)).visible = true
		else:
			get_node("Path3D" + str(ind)).temp = true

		ind += 1

	# remove any unused character sprites
	for i in range(ind, 7):
		get_node("Character Bubble" + str(i)).queue_free()

	MusicController.playMusic(ReferenceManager.get_reference("main.ogg"))

	# add start game and next round buttons to host screen
	if get_tree().get_unique_id() == 1:
		$Start.visible = true

	$Turn.text = gamestate.players[1] + "'s\nTurn"

func _on_Start_pressed() -> void:
	if(SaveManager.loaded_data):
		for i in range(0,SaveManager.Save["0"].Current_Round):
			next_round()
	else:
		SaveManager.Save["0"].Current_Round = 0	
	setup_dominos()
	
	$Start.queue_free()
	if (self_num == 0):
		$Next.visible = true
		
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))

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
	for i in range(7):
		# get domino info
		var domino_nums = draw_domino()
		var domino = Domino.instantiate()
		var domino_title = str(domino_nums[1]) + str(domino_nums[0])
		domino.get_node("Sprite2D").texture = load(ReferenceManager.get_reference("dominos/" + domino_title + ".png"))
		add_child(domino)

		# set domino position
		if i < 4:
			domino.position = Vector2(2000, 400 * i - 600)
		else:
			domino.position = Vector2(2250, 400 * (i - 4) - 600)

		# initialize domino
		domino.init(
			domino_nums[0],
			domino_nums[1],
			curriculum.domino_dict[domino_title][1],
			curriculum.domino_dict[domino_title][0],
			true
		)

# path set-up
func add_position(pos):
	position_table.append(pos)

# take a domino from the main deck
func draw_domino():
	var nums = dominos.pop_front()
	# print("len: ", len(dominos))
	if nums[0] < nums[1]:
		nums.invert()
	# print(nums, len(dominos))

	# update every player's deck to stay in sync
	rpc("update_deck")
	return nums

func clear_selected_domino():
	selected_domino = null

# Validate that a given domino is selected or not
func is_domino_selected(domino) -> bool:
	return selected_domino == domino

# Attempt to select domino. Return true if successful.
func select_domino(domino) -> bool:
	if selected_domino == null:
		selected_domino = domino
	return selected_domino == domino

# update deck from other player's drawing a domino
@rpc("any_peer") func update_deck():
	var _nums = dominos.pop_front()

# handles placing of domino onto a path
func place_domino(num):
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

			selected_domino.placed = true
			selected_domino.position = position_table[num] + placed_domino_offset[num]  # handles where the domnio is placed
			path_ends[num] = selected_domino.top_num
			end_dominos[num] = selected_domino

			placed_domino_offset[num] = placed_domino_offset[num] + Vector2(160, -176)

			num_placed += 1

			turn = (turn + 1) % len(gamestate.players)
			$Turn.text = gamestate.players[sorted_players[turn]] + "'s\nTurn"

			# if helped another player on their path, get a wellness bead
			if num < 6 and get_node("Path3D" + str(num + 1)).temp == true:
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
	# remove old domino if exists
	#if end_dominos[path_num]:
	#	end_dominos[path_num].queue_free()

	# create new placed domino
	var domino = Domino.instantiate()
	add_child(domino)
	domino.position = pos + placed_domino_offset[path_num]
	var domino_title = (
		str(min(domino_nums[0], domino_nums[1]))
		+ str(max(domino_nums[0], domino_nums[1]))
	)
	domino.get_node("Sprite2D").texture = load(ReferenceManager.get_reference("dominos/" + domino_title + ".png"))
	domino.init(domino_nums[0], domino_nums[1], domino_elms[0], domino_elms[1], true)
	domino.placed = true

	# update path
	path_ends[path_num] = domino_nums[1]
	end_dominos[path_num] = domino

	# flip domino sprite if necessary
	if flip:
		domino.get_node("Sprite2D").rotation_degrees = 180

	# change turn
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
	placed_domino_offset = [Vector2(0, 0), Vector2(0, 0), Vector2(0, 0),
							Vector2(0, 0), Vector2(0, 0), Vector2(0, 0), 
							Vector2(0, 0), Vector2(0, 0)]
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
			get_node("Path3D" + str(i)).visible = false

# handle when next round button pressed by host
func _on_Next_pressed() -> void:
	# reset field for host
	next_round()

	# reset field for everyone else
	for p in gamestate.players:
		if p != 1:
			rpc_id(p, "next_round")

	# get new dominos from deck
	if center_num <= 9:
		setup_dominos()
		SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
		
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
	elif round_num ==9:
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
	get_node("Path3D" + str(num)).visible = true

# remove player's path denoted by num from all player's screens
@rpc("any_peer") func remove_path(num):
	if get_node("Path3D" + str(num)).temp:
		get_node("Path3D" + str(num)).visible = false

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

func _on_Start_mouse_entered():
	$Start/MarginContainer/Label.set("theme_override_colors/font_color", green)
func _on_Start_mouse_exited():
	$Start/MarginContainer/Label.set("theme_override_colors/font_color", grey)
	
#### ^^^^ END BUTTON HOVER HANDLERS ^^^^ ####
