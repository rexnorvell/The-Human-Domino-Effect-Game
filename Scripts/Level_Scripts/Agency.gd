# narration scene to introduce oauabae and agency to kids

extends Node

@export var next_scene: PackedScene

var players_ready = []

# following text will be read out sequentially as narration
var dialogue = ["This O-shaped tool that looks like a magnifying glass is you. Well, it's you for this game, for the first part of the game, before you create your own avatar. You are controlling this magnifying tool.",
"This tool is several things at once. It's a magnifying glass for looking closer. It's also the letter O. Can you see how it looks like both things at once?",
"This word Oauabae comes from words from our oldest human family language that mean to observe, to nudge to attention, to have consciousness, to have ripple or wave",
"The word Aboo means to strum or play. So when you choose to use your Oauabae, it becomes your Oauabae-aboo",
"The things you choose to put into your Oauabae, things like your hopes, your likes, your interests, your dreams, you know, the things that's in your personality. The choices that forms your \"you,\" your Ouaube.",
"Yes this magnifying glass that looks like the letter O for Oauabae, has little spark too! That is the energy of your mind.",
"The little spark of energy in your Oauabae is light that burns brighter inside of you, as you learn and live at your very best. It's the activities, abilities and the choices in this world that makes your heart sings that sparks your Oauabae even more!",
"Only you know the real you. Yep, only you know your real Oauabae. You get to decide using your own agency.",
"The world is full of strings, and this one in the middle of the screen is quite special.",
"It represents your agency, your ability to choose who you want to be.",
"You deserve to have a vision for your life. Go ahead and seize your agency with your Oauabae!"
]

var page = 0
@onready var dialogue_label = $DialogueBox/DialogueText  # Assumes dialogue is a RichTextLabel node
@onready var timer = $DialogueBox/Timer  # Assumes there's a Timer node for text animation


func _ready() -> void:
	$Oauabae/AnimatedSprite2D.animation = "default"
	#$Narration.text = "This O-shaped tool that looks like a magnifying glass is you. Well, it's you for this game, for the first part of the game, before you create your own avatar. You are controlling this magnifying tool." 
	dialogue_label.text = dialogue[page]
	dialogue_label.set_visible_characters(0)
	timer.start()  # Start text reveal effect
	play_audio(page)  # Play first dialogue's audio    

	MusicController.playMusic(ReferenceManager.get_reference("quantum.ogg"))

func _on_End_timeout() -> void:
	if not multiplayer.is_server():
		# Tell server we are ready to start.
		rpc_id(1, "ready_to_start", multiplayer.get_unique_id())
	else:
		ready_to_start(multiplayer.get_unique_id())
	
# tell all player's what each player's chosen elcitraps are
@rpc("any_peer", "call_local") func set_elcitraps(elcitraps):
	gamestate.elcitraps[multiplayer.get_remote_sender_id()] = elcitraps
	
@rpc("any_peer") func start_game():
	get_parent().change_level(next_scene)

@rpc("any_peer") func ready_to_start(id):
	assert(multiplayer.is_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == gamestate.players.size():
		for p in gamestate.players:
			rpc_id(p, "start_game")
		start_game()

# advance narration or let player click on agency string
func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if page == 3:
			$String.visible = true
			$String/AnimationPlayer.play("Color")
		
		if page == len(dialogue)-1:
			$DialogueBox.hide()
			$String.input_pickable = true
			#print("hi")
		else:
			if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
				if page < dialogue.size() - 1:
					page += 1
					dialogue_label.text = dialogue[page]
					dialogue_label.set_visible_characters(0)
					timer.start()  # Restart text reveal effect
					play_audio(page)  # Play next dialogue's audio

func play_audio(page_index):
	# Stop all audio players
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()

	# Play the corresponding audio
	var audio_node_name = "AudioStreamPlayer" + str(page_index+1)
	var current_player = get_node(audio_node_name)
	if current_player:
		current_player.play()
	else:
		print("Audio node not found: ", audio_node_name)

func _on_Button_pressed():
	get_parent().change_level(next_scene)


func _on_Timer_timeout():
	dialogue_label.set_visible_characters(dialogue_label.get_visible_characters() + 1)
	if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
		timer.stop()  # Stop timer when all text is revealed
