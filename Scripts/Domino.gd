# node for domino on Domino Level
class_name Domino
extends Node2D

@export var top_num = 0
@export var bottom_num = 0
@export var top_element = ""
@export var bottom_element = ""


var original_pos = null
var _orig_y_sort := false
var _orig_z := 0
# Affects the Domino hand as well
#var og_scale = .5 # Hard coded to fit scale of CentralDomino Node2D in DominoWorld.tscn
#var hover_scale = og_scale + .05

var selected = false
@export var placed = false

# NEW: separate hover multipliers for hand vs. placed
@export var hand_hover_mult := 1.10     # 10% bump in the hand
@export var placed_hover_mult := 3   # 300% bump on the board

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
	z_index = 100000   # put it way on top

func _on_Area2D_mouse_exited() -> void:
	scale = _base_scale
	y_sort_enabled = _orig_y_sort
	z_index = _orig_z


func _on_Area2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Click once to "pick up" a domino
	if event is InputEventMouseButton:
		if event.is_pressed():
			if !placed:
				if !_world.is_domino_selected(self):
					if _world.select_domino(self):
						selected = true
				else:
					#TODO: Below line delays returning the domino in case the domino is being placed. This should be done in a better way
					await get_tree().create_timer(0.05).timeout
					# TODO: Need to fix position of domnio
					_world.clear_selected_domino()
					selected = false


func _physics_process(_delta):
	if selected and not placed:
		var mousePos = get_global_mouse_position()
		position.x = 2* (mousePos.x);
		position.y = 2* mousePos.y ;
	elif not placed:
		position = original_pos
