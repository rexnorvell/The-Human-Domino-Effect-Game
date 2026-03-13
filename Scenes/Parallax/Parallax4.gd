extends Control

@export var next_scene: PackedScene

signal trigger_animation(anim_name)

var dialogue = [
	"Welcome to The Human Domino Effect!",
	"Get ready to embark on an adventure that explores the journey of our human family!",
	"We are all connected across generations by a shared legacy. From our first small group of ancestors, you know, our shared ancient grandparents, we've grown to nearly 8 billion people! 8 billion human family cousins all living on our Earth today. We’ve built civilizations, created art, and advanced our human knowledge through all kinds of technology!",
	"Now we have the chance to learn from the past and work together to build a hopeful future. Through teamwork and balanced choices, we can make the world better for everyone.",
	"In The Human Domino Effect, every decision you make creates a chain reaction that impacts your own life and the lives of those around you; in your family, your school, your neighborhood, and even future generations!", 
	"This game teaches you how to navigate challenges, by making choices that bring help instead of harm, lifting others up, solving problems, and creating what we can see as a positive ripple effect, or a helpful Human Domino Effect in your human family!",
	"Are you ready to join the Human Family Team and make a helpful difference? Your journey starts now!"
]
var page: int = 0
var speed: int = 50
var direction: Vector2 = Vector2(-1, 0)
var accept_input: bool = true

@onready var dialogue_box: MarginContainer = $CanvasLayer/Dialogue
@onready var audio: Node = $Audio
@onready var parallax: ParallaxBackground = $ParallaxBackground


func _ready():
	emit_signal("trigger_animation", "Screen_Unwipe")
	dialogue_box.set_dialogue_text(dialogue[page])
	play_audio()


func _process(delta):
	parallax.scroll_base_offset += direction * speed * delta


func _input(event):
	if accept_input:
		if event is InputEventMouseButton and event.is_pressed():
			if dialogue_box.is_text_fully_visible():
				if page < dialogue.size() - 1:
					page += 1
					dialogue_box.set_dialogue_text(dialogue[page])
					play_audio()
				else:
					stop_audio()
					accept_input = false
					dialogue_box.play_animation("Out", true)
					dialogue_box.animation_done.connect(_on_animation_done)
			else:
				dialogue_box.reveal_text()


func _on_animation_done() -> void:
	get_parent().change_level(next_scene, true)


func stop_audio():
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()


func play_audio():
	stop_audio()
	var audio_node_name: String = "Audio/AudioStreamPlayer" + str(page)
	var current_player: AudioStreamPlayer = get_node(audio_node_name)
	if current_player:
		current_player.play()
