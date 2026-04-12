extends Control

const LISTEN_PORT = 10568
var listener_peer: PacketPeerUDP
var known_servers = {}

@onready var server_list_container = $Panel/ServerList
@onready var back_button = $Panel/BackButton

func _ready():
	listener_peer = PacketPeerUDP.new()
	visibility_changed.connect(_on_visibility_changed)
	
	back_button.pressed.connect(func(): self.visible = false)
	
func _on_visibility_changed():
	if visible:
		var err = listener_peer.bind(LISTEN_PORT)
		if err != OK:
			print("Error: Could not bind UDP listener. Port might be in use.")
	else:
		listener_peer.close()
		for child in server_list_container.get_children():
			child.queue_free()

func _process(_delta):
	if visible and listener_peer.get_available_packet_count() > 0:
		var server_ip = listener_peer.get_packet_ip()
		var packet = listener_peer.get_packet()
		
		var data_string = packet.get_string_from_ascii()
		var room_info = JSON.parse_string(data_string)
		
		if room_info != null:
			var safe_name = str(room_info["name"]).validate_node_name()
			
			if server_list_container.has_node(safe_name):
				var btn = server_list_container.get_node(safe_name)
				var status = "Waiting in Lobby"
				if room_info["started"]: status = "Game in Progress"
				
				btn.text = "%s | Players: %s/%s | %s" % [room_info["name"], room_info["players"], room_info["max_players"], status]
				btn.disabled = room_info["started"]
			else:
				_add_server_to_ui(server_ip, room_info, safe_name)

func _add_server_to_ui(ip: String, info: Dictionary, safe_name: String):
	var btn = Button.new()
	btn.name = safe_name
	
	var status = "Waiting in Lobby"
	if info["started"]: status = "Game in Progress"
	
	btn.text = "%s | Players: %s/%s | %s" % [info["name"], info["players"], info["max_players"], status]
	
	if info["started"]:
		btn.disabled = true
		
	btn.pressed.connect(func(): _on_join_server_pressed(ip))
	server_list_container.add_child(btn)

func _on_join_server_pressed(ip: String):
	var my_name = "Student_" + str(randi() % 1000)
	
	gamestate.join_game(ip, my_name)
	
	self.visible = false
