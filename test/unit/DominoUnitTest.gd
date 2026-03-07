# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name DominoUnitTest
extends GdUnitTestSuite

# TestSuite generated from
const __source = "res://Scenes/Components/Domino.gd"
const __prefab_source = "res://Scenes/Components/Domino.tscn"

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
	# Move mouse outside domino
	runner.simulate_mouse_move(Vector2(5000, 5000))
	await runner.simulate_frames(5, 10)
	var pre_scale := test_domino.scale

	# Hover mouse over domino
	runner.simulate_mouse_move(test_domino.global_position)
	await runner.simulate_frames(5, 10)

	# Confirm current scale doesn't equal previous scale
	assert_that(test_domino.scale).is_not_equal(pre_scale)


func test_mouse_exited_scale_down():
	# Hover mouse over domino
	runner.simulate_mouse_move(test_domino.global_position)
	await runner.simulate_frames(5, 10)
	var pre_scale := test_domino.scale

	# Move mouse outside domino
	runner.simulate_mouse_move(Vector2(5000, 5000))
	await runner.simulate_frames(5, 10)

	# Confirm current scale doesn't equal previous scale
	assert_that(test_domino.scale).is_not_equal(pre_scale)


func test_input_event_pickup_domino():
	var world_mock = init_world_mock()

	# Mock method calls
	do_return(false).on(world_mock).is_domino_selected(test_domino)
	do_return(true).on(world_mock).select_domino(test_domino)

	# Hover mouse over domino
	runner.simulate_mouse_move(test_domino.global_position)
	await get_tree().process_frame

	# Confirm domino isn't selected
	assert_bool(domino_spy.selected).is_false()

	# Click domino
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await get_tree().process_frame
	
	# Confirm domino is selected
	assert_bool(domino_spy.selected).is_true()

"""
func test_input_event_drop_domino():
	var world_mock = init_world_mock()

	# Mock method calls for pre-check
	do_return(false).on(world_mock).is_domino_selected(test_domino)
	do_return(true).on(world_mock).select_domino(test_domino)

	# Hover mouse over domino and click
	runner.simulate_mouse_move(test_domino.global_position)
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await get_tree().process_frame

	# Confirm domino is selected
	assert_bool(domino_spy.selected).is_true()

	# Click to place domino
	runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	await get_tree().process_frame

	# Confirm domino isn't selected
	assert_bool(domino_spy.selected).is_false()
"""

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
	var world_mock = mock("res://Scenes/Level_4_DominoWorld/DominoWorld.gd") as DominoWorld

	# Inject mocked world into domino
	test_domino._world = world_mock
	return world_mock
