extends Control

@onready var LobbyContainer = $Lobby_Container
@onready var LevelSelectContainer = $LevelSelect_Container
@onready var WaitRoomContainer = $WaitRoom_Container

@onready var waitroom_host_name = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Host_Username
@onready var waitroom_host_ip = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Host_IP

var local_ip = get_local_ip()
var selected_icon: String = ""  
var player_icon_buttons: Dictionary[String, Button] = {}
var icons_loaded: bool = false

const ICON_NAMES: Array[String] = [
	"basket.png", "boat.png", "bowandarrow.png", "campfire.png",
	"fire.png", "spear.png", "stone.png", "sun.png", "sunshine.png", "wheel.png"
]

func _ready():
	LevelSelectContainer.visible = false
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

func _on_Host_pressed():
	if get_player_name() == "":
		set_error_label("Invalid name!")
		SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
		return

	set_error_label("")
	# Load the level select menu with transition
	change_menu_smoothly(LobbyContainer, LevelSelectContainer)

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
	
	load_player_icons()
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
	var players = gamestate.get_player_list()
	players.sort()
	$WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/VBoxContainer/Menu/MarginContainer/ItemList.clear()
	for p in players:
		$WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/VBoxContainer/Menu/MarginContainer/ItemList.add_item(p)

	# Ensure Start button is visible and properly configured
	_update_start_button_state()
	
	if multiplayer.is_server():
		rpc("sync_all_icons", gamestate.player_icon)

# handle which level to begin at / randomize dominos
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
	
	var player_name = get_player_name()
	
	var err = gamestate.host_game(player_name)
	
	if err != OK:
		# If it fails, send them back to the main lobby and show the error
		change_menu_smoothly(LevelSelectContainer, LobbyContainer)
		_on_game_error("Port already in use. Cannot host.")
		return
	
	change_menu_smoothly(LevelSelectContainer, WaitRoomContainer)
	
	# Wait for animation to finish and everything to settle
	await WaitRoomContainer.get_node("AnimationPlayer").animation_finished
	# Additional frame waits to ensure nodes are ready
	await get_tree().process_frame
	await get_tree().process_frame
	
	refresh_lobby()
	await get_tree().process_frame
	
	print("=== Loading player icons (Host) ===")
	load_player_icons()
	print("=== Icons loaded. Total buttons: ", player_icon_buttons.size(), " ===")
	
	_update_start_button_state()

func get_player_name() -> String:
	return $Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/Name/NinePatchRect/MarginContainer/LineEdit.text
	
func set_player_name(name: String):
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/VBoxContainer/Name/NinePatchRect/MarginContainer/LineEdit.set_text(name)

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
	var start_button: TextureButton = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Start_Button
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

		print("Start button visible. Disabled? ", start_button.disabled)
	else:
		# Hide it completely for clients
		start_button.visible = false
		start_button.hide()

# Returns the Texture2D for an icon name like "basket.png",
# or null if we can't resolve it.
func _get_icon_texture(icon_name: String) -> Texture2D:
	var ref_key: String = "player_icons/" + icon_name

	if not ReferenceManager.refDict.has(ref_key):
		print("SKIP: no ref for ", ref_key)
		return null

	var tex_path: String = str(ReferenceManager.get_reference(ref_key))
	if tex_path == "" or tex_path == "null":
		print("SKIP: ref key exists but resolved to empty path for ", ref_key)
		return null

	if not ResourceLoader.exists(tex_path):
		print("SKIP: resource not found at path: ", tex_path)
		return null

	var tex := load(tex_path)
	if tex is Texture2D:
		return tex
	else:
		print("SKIP: loaded resource at ", tex_path, " but it's not a Texture2D")
		return null

func load_player_icons() -> void:
	var grid: GridContainer = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/IconGrid
	if not is_instance_valid(grid):
		print("ERROR: IconGrid node not found!")
		return

	grid.visible = true
	grid.show()

	# Clear old icons from the grid
	for child in grid.get_children():
		child.queue_free()
	player_icon_buttons.clear()

	print("Loading icons into IconGrid...")

	for icon_name in ICON_NAMES:
		var tex: Texture2D = _get_icon_texture(icon_name)
		if tex == null:
			continue  # skip this one, we already logged why

		# Create a button for this icon.
		# We use normal Button with a TextureRect child instead of TextureButton
		# so we ALWAYS visually see the art.
		var btn := Button.new()
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.custom_minimum_size = Vector2(72, 72)
		btn.clip_contents = true
		btn.name = "Icon_" + icon_name.get_basename()

		# Make a TextureRect child that fills the button area and shows the icon.
		var img := TextureRect.new()
		img.texture = tex
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.anchor_left = 0.0
		img.anchor_top = 0.0
		img.anchor_right = 1.0
		img.anchor_bottom = 1.0
		img.offset_left = 4
		img.offset_top = 4
		img.offset_right = -4
		img.offset_bottom = -4
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE  # let clicks hit the button

		btn.add_child(img)

		# Connect click -> choose this icon
		btn.pressed.connect(_on_icon_selected.bind(icon_name))

		# Add to layout and record it
		grid.add_child(btn)
		player_icon_buttons[icon_name] = btn

		print("  Added icon: ", icon_name, " tex size=", tex.get_size())

	# Pick a default icon if somehow nothing set yet
	if selected_icon == null or selected_icon == "":
		selected_icon = "basket.png"

	# Mark which one is selected visually
	_highlight_selected_icon()

	# Update Start button enable/disable state
	_update_start_button_state()

	icons_loaded = true
	print("Icon load complete. Total buttons: ", player_icon_buttons.size())

func _on_icon_selected(icon_name: String) -> void:
	print("Icon selected: ", icon_name)
	selected_icon = icon_name
	set_player_icon(icon_name)

	_highlight_selected_icon()

	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))

	_update_start_button_state()

func set_player_icon(icon_name: String):
	var player_id = multiplayer.get_unique_id()
	if player_id in gamestate.players:
		gamestate.player_icon[player_id] = icon_name
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
	
	for icon_file: String in player_icon_buttons.keys():
		var btn: Button = player_icon_buttons[icon_file]
		if not is_instance_valid(btn):
			continue
		btn.button_pressed = (icon_file == selected_icon)
		
		if icon_file in taken_icons and icon_file != selected_icon:
			btn.disabled = true
			btn.modulate = Color(0.4, 0.4, 0.4, 0.8) # Darkens the texture
		else:
			btn.disabled = false
			btn.modulate = Color.WHITE

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
	if icons_loaded:
		_highlight_selected_icon()

func _get_available_icons() -> Array[String]:
	var taken = gamestate.player_icon.values()
	var available: Array[String] = []
	for icon in ICON_NAMES:
		if not icon in taken:
			available.append(icon)
	return available
	
func _on_back_button_pressed() -> void:
	gamestate.disconnect_network()

func _on_Char_Creation_pressed():
	handle_level("Agency")

func _on_Pond_Choices_pressed():
	handle_level("Pond")

func _on_Domino_Game_pressed():
	handle_level("DominoWorld")

func _on_Virtual_World_pressed():
	handle_level("VW0")
	
func _on_Start_Button_pressed():
	if selected_icon == null or selected_icon == "":
		print("ERROR: Cannot start game - no icon selected!")
		return
	
	print("Start button pressed! Selected icon: ", selected_icon)
	gamestate.begin_game()
