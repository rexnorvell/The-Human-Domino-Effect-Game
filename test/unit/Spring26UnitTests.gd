class_name Spring26UnitTests
extends GdUnitTestSuite


# Tests
func test_button_border_animation_plays():
	
	# Load and instantiate the scene
	var scene: PackedScene = load("res://Scenes/Components/AnimatedButton.tscn")
	var button = scene.instantiate()
	add_child(button)
	await get_tree().process_frame

	# Hover over the button
	button.emit_signal("mouse_entered")

	# Assert the border is drawn after 0.2 seconds
	await get_tree().create_timer(0.2).timeout
	var style: StyleBoxFlat = button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_that(style).is_not_null()
	var has_border := (
		style.border_width_left > 0 or
		style.border_width_right > 0 or
		style.border_width_top > 0 or
		style.border_width_bottom > 0
	)
	assert_that(has_border).is_true()
	
	# Unhover the button
	button.emit_signal("mouse_exited")

	# Assert the border is removed after 0.2 seconds
	await get_tree().create_timer(0.2).timeout
	style = button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_that(style).is_not_null()
	has_border = (
		style.border_width_left > 0 or
		style.border_width_right > 0 or
		style.border_width_top > 0 or
		style.border_width_bottom > 0
	)
	assert_that(has_border).is_false()


func test_level_one_dialogue_skips():
	
	# Load and instantiate the scene
	var scene: PackedScene = load("res://Scenes/level_1_character_creation/Part1Agency.tscn")
	var level = scene.instantiate()
	var dialogue = level.get_node("Dialogue")
	add_child(level)
	await get_tree().process_frame

	# Click the screen
	var event := InputEventMouseButton.new()
	event.pressed = true
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = Vector2(100, 100)
	Input.parse_input_event(event)
	await get_tree().process_frame

	# Assert the dialogue is skipped
	var is_visible: bool = dialogue.is_text_fully_visible()
	assert_that(is_visible).is_true()
