extends Node

@export var next_scene: PackedScene

var dialogue = ["This O-shaped tool that looks like a magnifying glass is you. Well, it's you for this game, for the first part of the game, before you create your own avatar. You are controlling this magnifying tool.",
"This O-shaped magnifying glass has a special name. It's called an Oauabae. One of the things it does is to help you see things more closely, more clearly, more critically.",
"This word \"Oauabae\" comes from words from our oldest human family language that mean to observe, to nudge to attention, to have consciousness, to ripple or wave.",
"The word \"Aboo\" means to strum or play, so when you choose to use your Oauabae, your magnifying glass that looks like an O, it becomes your Oauabae-aboo.",
"Yes, this magnifying glass that looks like the letter \"O\" for the word \"Oauabae\" has a little spark, too! That is the energy of your mind.",
"The little spark of energy in your Oauabae is the light that burns brighter inside of you, as you learn and live at your very best. It's the activities, abilities, and choices in our world that make your heart sing, that also make your Oauabae spark even brighter! It's the interests that get your attention most and the things that give you energy to make your life and the lives of others better.",
"You see, only you knows the real you. Yep, only you know your real Oauabae. You get to decide. You deserve to have a vision of your life. You deserve to choose your Oauabae.",
"In this game world, the world is full of particles and strings, and this string in the middle of the screen is quite special.",
"It represents your agency, your ability to choose who you want to be.",
"You deserve to have a vision for your life. Go ahead and capture your agency using your Oauabae tool!",
# CAPTURE AGENCY
"The things that you choose to put into your Oauabae, things like your hopes, your likes, your interests, your dreams, you know, the things that are in your personality. The choices that form your \"you,\" your Oauabae. Isn't it strange that the most important part of you, all these things that make up you, are invisible in real life? In this game, you can see the most important part of you: your Oauabae.",
"Move your Oauabae around the shoreline. Look at the spinning elcitraps through your Oauabae. See them spinning there? Yes, the colorful, spinning discs. You might have noticed that \"elcitrap\" is the word \"particle\" spelled backwards. See, the choices you see in your real life are like particles that make up the real you and allow them to bring you wellness and fulfillment in your life.",
"Observe each one by hovering over them. Look to see which one of those resonate with you, which one makes you feel happy or healthy or free. Catch it as it spins. The things that you choose will become part of your player for the game, part of your Oauabae, and then your avatar. Pick the endeavors that are meaningful to you. Make a decision about your identity. That is your Oauabae. It's a fun way to think about building your \"you.\""
# CAPTURE ELCITRAPS
# Any other messages go here
]

var page = 0
var waiting_on_capture: bool = false
const AGENCY_APPEAR_PAGE = 7
const AGENCY_CAPTURE_PAGE = AGENCY_APPEAR_PAGE + 2
const ELCITRAP_APPEAR_PAGE = 1
const ELCITRAP_CAPTURE_PAGE = 1
const NUM_AUDIO_TRACKS = 13
@onready var dialogue_label = $DialogueBox/DialogueText
@onready var timer = $DialogueBox/Timer


func _ready() -> void:
	$Oauabae/AnimatedSprite2D.animation = "default"
	await get_tree().create_timer(0.5).timeout
	dialogue_label.text = dialogue[page]
	dialogue_label.set_visible_characters(0)
	timer.start()
	play_audio()
	MusicController.playMusic(ReferenceManager.get_reference("quantum.ogg"))


func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if page == AGENCY_CAPTURE_PAGE and dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count() and $DialogueBox.visible:
			$DialogueBox.hide()
			$String.input_pickable = true
			waiting_on_capture = true
			stop_audio()
		elif page == NUM_AUDIO_TRACKS - 1 and dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
			_next_scene()
		elif !waiting_on_capture:
			if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
				if page < NUM_AUDIO_TRACKS - 1:
					next_page()
			else:
				dialogue_label.set_visible_characters(dialogue_label.get_total_character_count())


func next_phase():
	waiting_on_capture = false
	if page == AGENCY_CAPTURE_PAGE:
		$DialogueBox.show()
	next_page()


func next_page():
	page += 1
	if page == AGENCY_APPEAR_PAGE:
		$String.visible = true
		$String/Sprite2D/AnimationPlayer.play("In")
	dialogue_label.text = dialogue[page]
	dialogue_label.set_visible_characters(0)
	timer.start()
	play_audio()


func stop_audio():
	for child in $Audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()


func play_audio():
	stop_audio()
	var audio_node_name = "Audio/AudioStreamPlayer" + str(page + 1)
	var current_player = get_node(audio_node_name)
	if current_player:
		current_player.play()
	else:
		print("Audio node not found: ", audio_node_name)


func _next_scene():
	get_parent().change_level(next_scene)


func _on_Timer_timeout():
	dialogue_label.set_visible_characters(dialogue_label.get_visible_characters() + 1)
	if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
		timer.stop()
