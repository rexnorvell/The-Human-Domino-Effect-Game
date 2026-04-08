# GdUnit generated TestSuite
#warning-ignore-all:unused_argument
#warning-ignore-all:return_value_discarded
class_name DominoWorldStalemateTest
extends GdUnitTestSuite

# TestSuite for stalemate detection logic in DominoWorld.gd
# Tests cover _check_stalemate() and _consecutive_help_count behavior
# These tests are RED (failing) until Plan 01-01 implements the logic.

const __source = "res://Scenes/Level_4_DominoWorld/DominoWorld.gd"
const __prefab_source = "res://Scenes/Level_4_DominoWorld/DominoWorld.tscn"

# NOTE: DominoWorld has complex multiplayer and autoload dependencies.
# Tests instantiate the script directly when possible to avoid scene-level
# dependency issues, falling back to state-variable inspection.


# Test 1: _check_stalemate returns true when no valid moves exist
# Sets up a single-player scenario where the player's domino cannot match any path end.
func test_check_stalemate_returns_true_when_no_valid_moves() -> void:
	var dw = load(__source).new()
	auto_free(dw)

	# Single player with id 1
	dw.sorted_players = [1]
	# Personal path ends at 5 (index 0)
	dw.path_ends = [5, 0, 0, 0, 0, 0, 0, 0]
	# Player has domino 3-4 — no match for 5
	dw.all_player_hands = {1: [[3, 4]]}
	dw.cpu_hands = {}
	# No trains open
	dw.train_open = [false, false, false, false, false, false, false, false]

	var result = dw._check_stalemate()
	assert_bool(result).is_true()


# Test 2: _check_stalemate returns false when the player has a valid move
# Player holds a domino that matches their personal path end.
func test_check_stalemate_returns_false_when_player_has_valid_move() -> void:
	var dw = load(__source).new()
	auto_free(dw)

	dw.sorted_players = [1]
	dw.path_ends = [5, 0, 0, 0, 0, 0, 0, 0]
	# Player has domino 5-3 — matches path_end 5
	dw.all_player_hands = {1: [[5, 3]]}
	dw.cpu_hands = {}
	dw.train_open = [false, false, false, false, false, false, false, false]

	var result = dw._check_stalemate()
	assert_bool(result).is_false()


# Test 3: _check_stalemate considers open trains
# Neither player matches their own path, but if an open train matches a held domino
# then a move is available — stalemate is false.
func test_check_stalemate_returns_false_when_open_train_available() -> void:
	var dw = load(__source).new()
	auto_free(dw)

	dw.sorted_players = [1, 2]
	# Path index 0 -> player 1 ends at 5, path index 1 -> player 2 ends at 7
	dw.path_ends = [5, 7, 0, 0, 0, 0, 0, 0]
	# Both players hold dominoes that don't match their own paths
	dw.all_player_hands = {1: [[3, 4]], 2: [[3, 4]]}
	dw.cpu_hands = {}
	# Player 2's train is open (index 1)
	dw.train_open = [false, true, false, false, false, false, false, false]

	# Neither player holds a domino matching path_end 5 or 7 — should be stalemate
	var result_stalemate = dw._check_stalemate()
	assert_bool(result_stalemate).is_true()

	# Now give player 1 a domino matching the open train end (7)
	dw.all_player_hands = {1: [[7, 2]], 2: [[3, 4]]}

	# Player 1 can play on the open train — not a stalemate
	var result_no_stalemate = dw._check_stalemate()
	assert_bool(result_no_stalemate).is_false()


# Test 4: _consecutive_help_count exists and initializes to 0
# This is a state-variable presence check. The variable is added in Plan 01-01.
func test_consecutive_help_count_exists() -> void:
	var dw = load(__source).new()
	auto_free(dw)

	# _consecutive_help_count must exist and default to 0
	assert_int(dw._consecutive_help_count).is_equal(0)
