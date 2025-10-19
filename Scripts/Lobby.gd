extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
@onready var LobbyContainer = $Lobby_Container
@onready var LevelSelectContainer = $LevelSelect_Container
@onready var WaitRoomContainer = $WaitRoom_Container

@onready var waitroom_host_name = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Host_Username
@onready var waitroom_host_ip = $WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Host_IP

var local_ip = get_local_ip()

# Called when the node enters the scene tree for the first time.
func _ready():
			
	LevelSelectContainer.visible = false
	WaitRoomContainer.visible = false
	
	# gamestate.gd signal event listeners
	gamestate.connect("player_list_changed", Callable(self, "refresh_lobby"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

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
	
	#var ip =  $Connect/JoinBox/IPAddress.text
	#if not ip.is_valid_ip_address():
		#set_error_text("Invalid IP Address")
		#return
		
	#get host name
	var host_ip = $Lobby_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Join/NinePatchRect/MarginContainer/LineEdit.text
	if host_ip == $Lobby_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Name/NinePatchRect/MarginContainer/LineEdit.text:
		set_error_label("Host and player can not have the same name.")
		SFXController.playSFX(ReferenceManager.get_reference("back.wav"))
		return

	set_error_label("")
	
	# Disable Host and Join buttons
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Host.disabled = true
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Join/Join_Button.disabled = true

	var player_name = get_player_name()
	# Set host username and ip address labels
	waitroom_host_name.set_text("Host: ")
	waitroom_host_ip.set_text("Host IP: " + host_ip)
	
	change_menu_smoothly(LobbyContainer, WaitRoomContainer)
	gamestate.join_game(host_ip, player_name)

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

	$WaitRoom_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Start_Button.disabled = not multiplayer.is_server()

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
	
	# Change menu to waiting room
	change_menu_smoothly(LevelSelectContainer, WaitRoomContainer)
	
	var player_name = get_player_name()
	gamestate.host_game(player_name)
	refresh_lobby()
	
##### VVV HELPER FUNCTIONS VVV #####

func get_player_name() -> String:
	return $Lobby_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Name/NinePatchRect/MarginContainer/LineEdit.text
	
func set_player_name(name: String):
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/MarginContainer/VBoxContainer/Name/NinePatchRect/MarginContainer/LineEdit.set_text(name)

func set_error_label(text: String):
	$Lobby_Container/HBoxContainer/MenuContainer/Menu/Error_Label.set_text(text)

func get_local_ip():
	var ip_address = "null"
	
	if OS.has_feature("Windows"):
		ip_address = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	elif OS.has_feature("X11") or OS.has_feature("OSX"):
		ip_address = IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)

	return ip_address

##### VVV LEVEL SELECT BUTTONS VVV #####

func _on_Char_Creation_pressed():
	handle_level("Agency")

func _on_Pond_Choices_pressed():
	handle_level("Pond")

func _on_Domino_Game_pressed():
	handle_level("DominoWorld")

func _on_Virtual_World_pressed():
	handle_level("VW0")
	
func _on_Start_Button_pressed():
	gamestate.begin_game()
