extends Node

@export var next_scene: PackedScene

var players_ready = []

var dialogue = ["This O-shaped tool that looks like a magnifying glass is you. Well, it's you for this game, for the first part of the game, before you create your own avatar. You are controlling this magnifying tool.",
"This tool is several things at once. It's a magnifying glass for looking closer. It's also the letter \"O.\" Can you see how it looks like both things at once?",
"This word \"Oauabae\" comes from words from our oldest human family language that mean to observe, to nudge to attention, to have consciousness, to ripple or wave.",
"The word \"Aboo\" means to strum or play, so when you choose to use your Oauabae, your magnifying glass that looks like an O, it becomes your Oauabae-aboo.",
"The things that you choose to put into your Oauabae, things like your hopes, your likes, your interests, your dreams, you know, the things that are in your personality. The choices that form your \"you,\" your Oauabae. Isn't it strange that the most important part of you, all these things that make up you, are invisible in real life? In this game, you can see the most important part of you: your Oauabae.",
"Yes, this magnifying glass that looks like the letter \"O\" for the word \"Oauabae\" has a little spark, too! That is the energy of your mind.",
"The little spark of energy in your Oauabae is the light that burns brighter inside of you, as you learn and live at your very best. It's the activities, abilities, and choices in our world that make your heart sing, that also make your Oauabae spark even brighter! It's the interests that get your attention most and the things that give you energy to make your life and the lives of others better.",
"Remember, only you knows the real you. Yep, only you knows your real Oauabae. You get to decide by using your own agency. Your agency is the most important thing to put into your Oauabae. It is your decision to make sure that the things that you experience are what are best for you, and if they're not, you get to speak up and make a change so that you can live your best life. This agency is the first thing to put into your Oauabae.",
"In this game world, the world is full of particles and strings, and this string in the middle of the screen is quite special.",
"It represents your agency, your ability to choose who you want to be.",
"You deserve to have a vision for your life. Go ahead and capture your agency using your Oauabae tool!"
]

var page = 0
@onready var dialogue_label = $DialogueBox/DialogueText
@onready var timer = $DialogueBox/Timer


func _ready() -> void:
	$Oauabae/AnimatedSprite2D.animation = "default"
	await get_tree().create_timer(0.5).timeout
	dialogue_label.text = dialogue[page]
	dialogue_label.set_visible_characters(0)
	timer.start()
	play_audio(page)
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


# Advance narration or let player click on agency string
func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if page == 3 and !$String.visible:
			$String.visible = true
			$String/AnimationPlayer.play("Color")
		elif page == len(dialogue) - 1 and dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count() and $DialogueBox.visible:
			$DialogueBox.hide()
			$String.input_pickable = true
			stop_audio()
		else:
			if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
				if page < dialogue.size() - 1:
					page += 1
					dialogue_label.text = dialogue[page]
					dialogue_label.set_visible_characters(0)
					timer.start()
					play_audio(page)
			else:
				dialogue_label.set_visible_characters(dialogue_label.get_total_character_count())


func stop_audio():
	for child in get_children():
			if child is AudioStreamPlayer:
				child.stop()


func play_audio(page_index):
	stop_audio()
	var audio_node_name = "AudioStreamPlayer" + str(page_index + 1)
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
		timer.stop()
