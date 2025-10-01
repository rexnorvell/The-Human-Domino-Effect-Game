# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name DominoUnitTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = "res://Domino.gd"
const __prefab_source = "res://Domino.tscn"

var test_domino: Domino
var domino_spy
var runner: GdUnitSceneRunner


# Test cases
# Before all tests are ran
func before():
	test_domino = load(__prefab_source).instantiate()
	domino_spy = spy(test_domino)
	runner = scene_runner(domino_spy)


# Before each individual test is ran
func before_test():
	reset(domino_spy)


func test__ready_in_group() -> void:
	# Executes _ready() on creation
	assert_bool(domino_spy.is_in_group("dominos")).is_true()
	assert_object(domino_spy.original_pos).is_not_null()


# Parameterized to account for different scenarios
func test_init_initial(
	domino_num_top: int,
	domino_num_bot: int,
	domino_num_element_top: String,
	domino_num_element_bot: String,
	initial: bool,
	expected_label_text: String,
	test_parameters := [
		[0, 0, "testUp", "testDn", false, "testDn\n0 | 0\ntestUp"],
		[0, 0, "testUp", "testDn", true, "testDn\n0 | 0\ntestUp"],
	]
):
	# init(...) is called directly
	test_domino.init(
		domino_num_top, domino_num_bot, domino_num_element_bot, domino_num_element_top, initial
	)

	if initial:
		assert_float(domino_spy.original_pos.x).is_equal(domino_spy.position.x)
		assert_float(domino_spy.original_pos.y).is_equal(domino_spy.position.y)

	# Do some validation when running find_node() or variants. Test suite won't catch null values.
	var label = test_domino.find_child("Label")
	assert_object(label).is_instanceof(Label)

	# Verify that the label output is set correctly
	assert_str(label.text).is_equal_ignoring_case(expected_label_text)


func test_mouse_entered_scale_up():
	# Pre-check mouse is not hovering over domino
	runner.set_mouse_pos(Vector2(500, 500))
	# Wait a few frames before `*_Area2D_*` event is emitted
	await runner.simulate_frames(5, 10).completed

	# Get sprite scale before mouse entered
	# Get value only copy of node, rather than a reference
	var pre_sprite: Sprite2D = auto_free(test_domino.find_child("Sprite2D").duplicate())

	# Simulate mouse movement to center of domino
	runner.simulate_mouse_move(Vector2(0, 0))
	# Wait a few frames before `*_Area2D_*` event is emitted
	await runner.simulate_frames(5, 10).completed

	# Verify that sprite scale changed
	var sprite: Sprite2D = test_domino.find_child("Sprite2D")
	assert_vector2(sprite.scale).is_not_equal(pre_sprite.scale)
	assert_vector2(sprite.scale).is_equal(Vector2(domino_spy.hover_scale, domino_spy.hover_scale))


func test_mouse_exited_scale_down():
	# Pre-check mouse is hovering over domino
	runner.set_mouse_pos(Vector2(0, 0))
	# Wait a few frames before `*_Area2D_*` event is emitted
	await runner.simulate_frames(5, 10).completed

	# Get value only copy of node, rather than a reference
	var pre_sprite: Sprite2D = auto_free(test_domino.find_child("Sprite2D").duplicate())

	# Simulate mouse movement away from domino
	runner.simulate_mouse_move(Vector2(500, 500))
	# Wait a few frames before `*_Area2D_*` event is emitted
	await runner.simulate_frames(5, 10).completed

	# Verify that sprite scale changed
	var sprite: Sprite2D = test_domino.find_child("Sprite2D")
	assert_vector2(sprite.scale).is_not_equal(pre_sprite.scale)
	assert_vector2(sprite.scale).is_equal(Vector2(domino_spy.og_scale, domino_spy.og_scale))


func test_input_event_pickup_domino():
	var world_mock = init_world_mock()

	# Mock method calls
	do_return(false).on(world_mock).is_domino_selected(test_domino)
	do_return(true).on(world_mock).select_domino(test_domino)

	# Pre-check mouse is hovering over domino
	runner.set_mouse_pos(Vector2(0, 0))
	await await_idle_frame().completed

	assert_bool(domino_spy.selected).is_false()

	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await await_idle_frame().completed
	assert_bool(domino_spy.selected).is_true()


func test_input_event_drop_domino():
	var world_mock = init_world_mock()

	# Mock method calls for pre-check
	do_return(false).on(world_mock).is_domino_selected(test_domino)
	do_return(true).on(world_mock).select_domino(test_domino)

	# Pre-check mouse is hovering over domino and clicked to pick up.
	runner.set_mouse_pos(Vector2(0, 0))
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await await_idle_frame().completed

	assert_bool(domino_spy.selected).is_true()

	do_return(true).on(world_mock).is_domino_selected(test_domino)

	# Click on domino again. Should place.
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	# Account for timed pause when clicking on domino
	await runner.simulate_frames(5, 10).completed
	await await_idle_frame().completed

	assert_bool(domino_spy.selected).is_false()


# TODO: Determine if this is testable. `get_global_mouse_position` seems to behave strange under the test runner.
# func test_physics_process():
# 	test_domino.selected = false
# 	runner.set_mouse_pos(Vector2(0, 0))
# 	yield(await_idle_frame(), "completed")

# 	# Check
# 	assert_vector2(domino_spy.position).is_equal(domino_spy.original_pos)

# 	# Trigger domino to follow mouse
# 	test_domino.selected = true
# 	var mouse_position = Vector2(500, 500)

# 	runner.simulate_mouse_move(mouse_position)
# 	yield(await_idle_frame(), "completed")

# 	# Should have followed mouse position
# 	assert_vector2(domino_spy.position).is_equal(mouse_position)

### Helper functions


# Create a "mock" node for the domino node to call out to. We can control output of mock return values to setup specific testing scenarios.
func init_world_mock() -> DominoWorld:
	# Setup mock for DominoWorld.gd
	var world_mock = mock("res://levels/DominoWorld.gd") as DominoWorld

	# Inject mocked world into domino
	test_domino._world = world_mock
	return world_mock
