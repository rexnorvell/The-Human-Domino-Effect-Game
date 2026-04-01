extends Control

@onready var LobbyContainer = $Lobby_Container
@onready var LevelSelectContainer = $LevelSelect_Container
@onready var WaitRoomContainer = $WaitRoom_Container

@onready var waitroom_host_name = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Host_Username
@onready var waitroom_host_ip = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Host_IP

var local_ip = get_local_ip()
var selected_icon: String = ""  

const ICON_FILE_NAMES: Array[String] = [
	"basket.png", "boat.png", "bowandarrow.png", "campfire.png",
	"fire.png", "spear.png", "stone.png", "wheel.png"
]
const ICON_NAMES: Array[String] = ["Basket", "Boat", "BowAndArrow", "Campfire", "Fire", "Spear", "Stone", "Wheel"]


func _ready():
	# Start on the Level Select screen
	LobbyContainer.visible = false
	LevelSelectContainer.visible = true
	WaitRoomContainer.visible = false
	
	# gamestate.gd signal event listeners
	gamestate.connect("player_list_changed", Callable(self, "refresh_lobby"))
	gamestate.connection_failed.connect(_on_connection_failed)
	gamestate.join_accepted_signal.connect(_on_join_accepted)
	gamestate.game_error.connect(_on_game_error)
	
	# Listen for the back button being clicked so we can cleanly disconnect
	if has_node("Back_Button"):
		$Back_Button.pressed.connect(_on_back_button_pressed)
		
	# Set the placeholder text to your local IP address
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/IP/MarginContainer/LineEdit.placeholder_text = get_local_ip()
	set_player_name(gamestate.player_name)


func _on_Host_pressed():
	if get_player_name() == "":
		set_error_label("Invalid name!")
		SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
		return

	set_error_label("")
	
	# Set up dominos, create the host, and go to the Wait Room
	handle_level(gamestate.first_level)


func _on_Join_Button_pressed():
	if get_player_name() == "":
		set_error_label("Invalid name!")
		SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
		return
	
	var ip = $Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/IP/MarginContainer/LineEdit.text
	if ip.is_empty():
		ip = str(local_ip)

	set_error_label("Connecting...")

	# Disable Host and Join buttons
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/HBoxContainer/Host.disabled = true
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/HBoxContainer/Join/Join_Button.disabled = true

	# Set host username and ip address labels
	waitroom_host_name.set_text("Host: ")
	waitroom_host_ip.set_text("Host IP: " + ip)
	
	gamestate.join_game(ip, get_player_name())
	get_tree().create_timer(2.0).timeout.connect(_on_join_timeout)


func _on_join_timeout():
	if $Lobby_Container/HBoxContainer/MenuContainer/Menu/Error_Label.text == "Connecting...":
		gamestate.disconnect_network() # Abort the attempt under the hood
		_on_connection_failed() # Reset the UI buttons and show error


func _on_join_accepted():
	set_error_label("")
	
	var ip = $Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/IP/MarginContainer/LineEdit.text
	if ip.is_empty():
		ip = str(local_ip)
		
	waitroom_host_name.set_text("Host: ")
	waitroom_host_ip.set_text("Host IP: " + ip)
	
	change_menu_smoothly(LobbyContainer, WaitRoomContainer)
	
	await WaitRoomContainer.get_node("AnimationPlayer").animation_finished
	await get_tree().process_frame
	await get_tree().process_frame
	
	refresh_lobby()
	await get_tree().process_frame
	
	set_player_icon(selected_icon)
	_update_start_button_state()


func _on_connection_failed():
	_on_game_error("Connection failed. Server not found.")


func _on_game_error(what: String):
	set_error_label(what)
	# Turn the buttons back on for retry purposes
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/HBoxContainer/Host.disabled = false
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/HBoxContainer/Join/Join_Button.disabled = false


func change_menu_smoothly(prev, target):
	var prev_animation = prev.get_node("AnimationPlayer")
	var target_animation = target.get_node("AnimationPlayer")

	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	prev_animation.play_backwards("start")
	await prev_animation.animation_finished
	
	prev.visible = false
	target.visible = true
	target_animation.play("start")


func refresh_lobby():
	var item_list = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/VBoxContainer/Menu/MarginContainer/ItemList
	var players = gamestate.get_player_list()
	players.sort()
	item_list.clear()
	for p in players:
		var index = item_list.add_item(p)
		item_list.set_item_tooltip(index, " ")

	# Ensure Start button is visible and properly configured
	_update_start_button_state()
	
	if multiplayer.is_server():
		rpc("sync_all_icons", gamestate.player_icon)


func handle_level(level):
	gamestate.first_level = level

	for top in range(10):
		for bottom in range(top + 1):
			gamestate.dominos.append([bottom, top])

	randomize()
	gamestate.random_seed = randi() % 10000000
	seed(gamestate.random_seed)

	gamestate.dominos.shuffle()
	
	# Set host username and ip address labels
	waitroom_host_name.set_text("Host: " + get_player_name())
	waitroom_host_ip.set_text("Host IP: " + str(local_ip))
	
	# Attempt to host the game first
	var err = gamestate.host_game(get_player_name())
	
	if err != OK:
		# We are already in the LobbyContainer, so just show the error
		_on_game_error("Port already in use. Cannot host.")
		return
	
	change_menu_smoothly(LobbyContainer, WaitRoomContainer)
	
	await WaitRoomContainer.get_node("AnimationPlayer").animation_finished
	await get_tree().process_frame
	await get_tree().process_frame
	
	refresh_lobby()
	await get_tree().process_frame
	
	_update_start_button_state()


func get_player_name() -> String:
	return $Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/Name/NinePatchRect/MarginContainer/LineEdit.text


func set_player_name(pname: String):
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/Name/NinePatchRect/MarginContainer/LineEdit.set_text(pname)


func set_error_label(text: String):
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/Error_Label.set_text(text)


func get_local_ip() -> String:
	for addr in IP.get_local_addresses():
		# Look for standard physical home network ranges
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	# Fallback if disconnected from all networks
	return "127.0.0.1"


# Update Start button visibility and enabled state
func _update_start_button_state() -> void:
	var start_button: AnimatedButton = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/StartButton
	if not is_instance_valid(start_button):
		print("ERROR: Start button node not found!")
		return

	# Only the host is allowed to see and click the Start button
	if multiplayer.multiplayer_peer != null and multiplayer.is_server():
		start_button.visible = true
		start_button.show()
		
		# Enable only if an icon is chosen
		var has_selected_icon := selected_icon != null and selected_icon != ""
		start_button.disabled = not has_selected_icon
	else:
		# Hide it completely for clients
		start_button.visible = false
		start_button.hide()


func _on_icon_selected(icon_name: String) -> void:
	selected_icon = icon_name
	set_player_icon(icon_name)
	_highlight_selected_icon()
	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	_update_start_button_state()


func set_player_icon(icon_name: String):
	var player_id = multiplayer.get_unique_id()
	if player_id in gamestate.players:
		gamestate.player_icon[player_id] = icon_name
		_highlight_selected_icon()
		# Sync with other players if multiplayer
		if multiplayer.multiplayer_peer != null:
			if multiplayer.is_server():
				rpc("sync_player_icon", player_id, icon_name)
			else:
				rpc_id(1, "sync_player_icon", player_id, icon_name)


@rpc("any_peer") func sync_player_icon(player_id: int, icon_name: String):
	gamestate.player_icon[player_id] = icon_name
	if multiplayer.is_server():
		for peer in multiplayer.get_peers():
			if peer != player_id: # Don't echo it back to the client who just sent it
				rpc_id(peer, "sync_player_icon", player_id, icon_name)
	_highlight_selected_icon()


func _highlight_selected_icon() -> void:
	var taken_icons = gamestate.player_icon.values()
	for icon_name: String in ICON_NAMES:
		var button: PlayerIconButton = get_button_from_icon_name(icon_name)
		if button == null:
			continue
		var icon_file_name: String = icon_name.to_lower() + ".png"
		if icon_file_name != selected_icon:
			if icon_file_name in taken_icons:
				button.set_is_available(false)
			else:
				button.set_is_available(true)
		else:
			if !button.get_is_selected():
				button.press()


func get_button_from_icon_name(icon_name: String) -> PlayerIconButton:
	for button: PlayerIconButton in $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/GridContainer.get_children():
		if button.name == icon_name:
			return button
	return null


@rpc("any_peer", "call_local") func sync_all_icons(full_icon_dict: Dictionary):
	# Update local dictionary to match the host
	gamestate.player_icon = full_icon_dict
	var my_id = multiplayer.get_unique_id()
	
	# If I haven't picked an icon yet, pick a random unique one
	if not gamestate.player_icon.has(my_id):
		var available = _get_available_icons()
		if available.size() > 0:
			selected_icon = available.pick_random()
		else:
			selected_icon = "basket.png"
		set_player_icon(selected_icon)


func _get_available_icons() -> Array[String]:
	var taken = gamestate.player_icon.values()
	var available: Array[String] = []
	for icon in ICON_FILE_NAMES:
		if not icon in taken:
			available.append(icon)
	return available
	
	
func _on_back_button_pressed() -> void:
	gamestate.disconnect_network()


func _on_Char_Creation_pressed():
	start_single_player("Agency")


func _on_Pond_Choices_pressed():
	start_single_player("Pond")


func _on_Virtual_World_pressed():
	start_single_player("VW0")


func _on_Domino_Game_pressed():
	# Set the level, then transition to the Host/Join screen
	gamestate.first_level = "DominoWorld"
	change_menu_smoothly(LevelSelectContainer, LobbyContainer)


func start_single_player(level_name: String):
	gamestate.first_level = level_name
	# Host a local server behind the scenes on a random port
	gamestate.host_single_player("Player") 
	gamestate.begin_game() # Skip the wait room and go straight in


func _on_Start_Button_pressed():
	if selected_icon == null or selected_icon == "":
		print("ERROR: Cannot start game - no icon selected!")
		return
	print("Start button pressed! Selected icon: ", selected_icon)
	gamestate.begin_game()
