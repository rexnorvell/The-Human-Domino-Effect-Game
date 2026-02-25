extends Control

@export var next_scene: PackedScene

signal trigger_animation(anim_name)
signal trigger_zoom()
signal pan_stopped

var speed = 500
var direction = Vector2(-1, 0)

var dialogue = [
	"Welcome to The Human Domino Effect!",
	"Get ready to embark on an adventure that explores the journey of our Human Family!",
	"We are all connected across generations by a shared legacy. From our first small group of ancestors, you know, our shared ancient grandparents. We've grown to nearly 8 billion people! 8 billion human family cousins all living on our earth today. We’ve built civilizations, created art, and advanced our human knowledge through all kinds of technology!",
	"Now, we have the chance to learn from the past and work together to build a hopeful future. Through teamwork and balanced choices, we can make the world better for everyone.",
	"In The Human Domino Effect, every decision you make creates a chain reaction that impacts your own life and the lives of those around you; in your family, your school, your neighborhood and even in the future generations!", 
	"This game teaches you how to navigate challenges, by making choices that bring help, instead of harm, lifting others up, solving problems, and creating what we can see as a positive ripple effect, or helpful human dominoe effect in your human family!",
	"Are you ready to join the Human Family Team and make a helpful difference? Your journey starts now!"
]

var page = 0

@onready var parallax = $ParallaxBackground
@onready var dialogue_label = $Polygon2D/dialogue  # Assumes dialogue is a RichTextLabel node
@onready var timer = $Polygon2D/Timer  # Assumes there's a Timer node for text animation

func _ready():
	emit_signal("trigger_animation", "Screen_Unwipe")  # Emit animation signal
	dialogue_label.text = dialogue[page]
	dialogue_label.set_visible_characters(0)
	timer.start()  # Start text reveal effect
	play_audio(page)  # Play first dialogue's audio

func _process(delta):
	if parallax.scroll_offset.x >= -6125:  # Check if scrolling is still in progress
		parallax.scroll_offset += direction * speed * delta
	else:
		# Reset the scroll offset to the starting position
		parallax.scroll_offset.x = 0
		emit_signal("pan_stopped")  # Optionally emit the signal if needed


func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
			if page < dialogue.size() - 1:
				page += 1
				dialogue_label.text = dialogue[page]
				dialogue_label.set_visible_characters(0)
				timer.start()  # Restart text reveal effect
				play_audio(page)  # Play next dialogue's audio
			else:
				get_parent().change_level(next_scene)  # Change to next scene

func _on_Timer_timeout():
	dialogue_label.set_visible_characters(dialogue_label.get_visible_characters() + 1)
	if dialogue_label.get_visible_characters() >= dialogue_label.get_total_character_count():
		timer.stop()  # Stop timer when all text is revealed

func play_audio(page_index):
	# Stop all audio players
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()

	# Play the corresponding audio
	var audio_node_name = "AudioStreamPlayer" + str(page_index)
	var current_player = get_node(audio_node_name)
	if current_player:
		current_player.play()
	else:
		print("Audio node not found: ", audio_node_name)
