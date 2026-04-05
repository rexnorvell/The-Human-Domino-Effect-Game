class_name Spring26UnitTests
extends GdUnitTestSuite


# Hooks
func before():
	print('Before')


func before_test():
	print('Before test...')


# Tests
func test_button_border_animation_plays():
	
	# Load and instantiate the scene
	var scene: PackedScene = load("res://Scenes/Components/AnimatedButton.tscn")
	var button = scene.instantiate()
	add_child(button)
	await get_tree().process_frame

	# Hover over the button
	var event := InputEventMouseMotion.new()
	event.position = button.global_position
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
