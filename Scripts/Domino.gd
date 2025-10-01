# node for domino on Domino Level
class_name Domino
extends Node2D

@export var top_num = 0
@export var bottom_num = 0
@export var top_element = ""
@export var bottom_element = ""

var original_pos = null
# Affects the Domino hand as well
var og_scale = .5 # Hard coded to fit scale of CentralDomino Node2D in DominoWorld.tscn
var hover_scale = og_scale + 0.05
var selected = false
@export var placed = false

# Reference to world node to minimize `get_parent()` calls
var _world = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_world = get_parent()
	# change domino appearance
	if not placed:
		add_to_group("dominos")
	# Set initial scale to og_scale
	$Sprite2D.scale = Vector2(og_scale, og_scale)
	# Store original position for reference
	original_pos = position


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


func _on_Area2D_mouse_entered() -> void:
	$Sprite2D.scale = Vector2(hover_scale, hover_scale)


func _on_Area2D_mouse_exited() -> void:
	$Sprite2D.scale = Vector2(og_scale, og_scale)


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
