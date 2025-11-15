# node for domino on Domino Level
class_name Domino
extends Node2D

@export var top_num = 0
@export var bottom_num = 0
@export var top_element = ""
@export var bottom_element = ""


@export var original_pos = null
var _orig_y_sort := false
var _orig_z := 0
# Affects the Domino hand as well
#var og_scale = .5 # Hard coded to fit scale of CentralDomino Node2D in DominoWorld.tscn
#var hover_scale = og_scale + .05

var selected = false
@export var placed = false

# NEW: separate hover multipliers for hand vs. placed
@export var hand_hover_mult := 1.10 # 10% bump in the hand
@export var placed_hover_mult := 3 # 300% bump on the board

# Track the node’s base scale so we can return to it on mouse exit
var _base_scale: Vector2 = Vector2.ONE

# Reference to world node to minimize `get_parent()` calls
var _world = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Sprite2D.z_as_relative = true
	$Sprite2D.top_level = false
	$Sprite2D.z_index = 0
	_world = get_parent()
	# change domino appearance
	if not placed:
		add_to_group("dominos")
	# Set initial scale to og_scale
	#$Sprite2D.scale = Vector2(og_scale, og_scale)
	# Store original position for reference
	original_pos = position
	call_deferred("_capture_base_scale")

func _capture_base_scale() -> void:
	_base_scale = scale

func init(bottom, top, bottom_elm, top_elm, initial):
	bottom_num = bottom
	top_num = top

	if not bottom_elm:
		bottom_element = ""
	else:
		bottom_element = bottom_elm
	if not top_elm:
		top_element = ""
	else:
		top_element = top_elm
	if initial:
		original_pos = self.position
	$Label.text = bottom_element + "\n" + str(bottom) + " | " + str(top) + "\n" + top_element


# NEW: let the world update our notion of base scale when it changes the node scale
func set_base_scale(new_scale: Vector2) -> void:
	scale = new_scale
	_base_scale = new_scale

# NEW: helper called when a domino becomes placed
func mark_as_placed(new_scale: Vector2) -> void:
	placed = true
	set_base_scale(new_scale)

func _on_Area2D_mouse_entered() -> void:
	var mult: float
	if placed:
		mult = placed_hover_mult
	else:
		mult = hand_hover_mult

	# Scale the whole domino node so it works the same for hand/board
	scale = _base_scale * mult
	_orig_y_sort = y_sort_enabled
	y_sort_enabled = false
	_orig_z = z_index
	z_index = 10 # put it on top

func _on_Area2D_mouse_exited() -> void:
	scale = _base_scale
	y_sort_enabled = _orig_y_sort
	z_index = _orig_z


func _on_Area2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if placed:
			return # dont interact with placed dominoes

		var selected_domino = _world.get_selected_domino()

		# nothing selected → select this one
		if selected_domino == null:
			if _world.select_domino(self):
				selected = true
		# another domino already selected → swap with it
		elif selected_domino != self:
			swap(selected_domino)
			_world.call_deferred("clear_selected_domino")

		# clicking the same domino again → deselect
		else:
			# before deselecting, make sure there isnt actually another domino here
			var other_domino = get_domino_at_click()
			if other_domino:
				swap(other_domino)
			_world.call_deferred("clear_selected_domino")


func swap(other: Domino) -> void:
	# await get_tree().process_frame
	# Swap positions
	position = other.original_pos
	other.position = original_pos

	# Swap original positions for consistency
	original_pos = position
	other.original_pos = other.position

func deselect() -> void:
	selected = false
	if !placed:
		position = original_pos

func get_domino_at_click() -> Domino:
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state

	# Create query parameters
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true # detect Area2D (your dominoes)
	query.collide_with_bodies = false

	# Perform the query (max 10 results)
	var results = space_state.intersect_point(query, 10)

	# Return the first domino found that is not self
	for r in results:
		var node = r.collider
		if node is Domino and node != self:
			return node
	return null

func _physics_process(_delta):
	if selected and not placed:
		var mousePos = get_global_mouse_position()
		position.x = 2 * mousePos.x;
		position.y = 2 * mousePos.y;
	# elif not placed:
	# 	position = original_pos
