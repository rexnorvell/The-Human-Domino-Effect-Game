extends Node

@onready var TutorialContainer = $Tutorial_Container
@onready var LevelSelectContainer = $LevelSelect_Container

# Called when the node enters the scene tree for the first time.
func _ready():
	LevelSelectContainer.visible = false
	
	# gamestate.gd signal event listeners
	gamestate.connect("player_list_changed", Callable(self, "refresh_lobby"))
	#Enable tutorial mode flag
	gamestate.tutorial_mode = true 
	# If user press start without selecting level automatically goes to the first level
	
	# CS499 Fall 2024 Only DominoWorld have tutorial
	handle_level("DominoWorld")

# Function to start the game
func _on_Start_pressed():
	gamestate.begin_game()

# Load in the level selection menu
func _on_Select_pressed():
	# Load the level select menu with transition
	change_menu_smoothly(TutorialContainer, LevelSelectContainer)
	
func change_menu_smoothly(prev, target):
	var prev_animation = prev.get_node("AnimationPlayer")
	var target_animation = target.get_node("AnimationPlayer")

	SFXController.playSFX(ReferenceManager.get_reference("next.wav"))
	prev_animation.play_backwards("start")
	await prev_animation.animation_finished
	
	prev.visible = false
	target.visible = true
	target_animation.play("start")

func handle_level(level):
	gamestate.first_level = level

	#for top in range(10):
	#	for bottom in range(top + 1):
	#		gamestate.dominos.append([bottom, top])

	#randomize()
	#gamestate.random_seed = randi() % 10000000
	#seed(gamestate.random_seed)

	#gamestate.dominos.shuffle()
	
	# Change menu to waiting room
	change_menu_smoothly(LevelSelectContainer, TutorialContainer)
	
	# Host a game with a player name Tutorial
	var player_name = "Tutorial"
	gamestate.host_game(player_name)


### Helper Level Selection Function ####

func _on_Char_Creation_pressed():
	handle_level("Agency")

func _on_Pond_Choices_pressed():
	handle_level("Pond")

func _on_Domino_Game_pressed():
	handle_level("DominoWorld")

func _on_Virtual_World_pressed():
	handle_level("Sandbox")
	
