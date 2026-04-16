# node for domino path bubble

extends Node2D

@export var num = 0
@export var temp = false

# Color constants for indicator categories
const COLOR_PLAYER_PATH := Color(0.1, 0.9, 0.1, 0.8)     # green -- your valid path
const COLOR_SUN_PATH := Color(1.0, 0.84, 0.0, 0.8)        # gold -- sunrise/sunset
const COLOR_OPEN_TRAIN := Color(1.0, 0.5, 0.0, 0.8)       # orange -- other players' open trains

# Indicator state
var _base_scale: Vector2
var _indicator_active := false
var _valid_placement := false
var _train_open := false
var _indicator_color := COLOR_PLAYER_PATH
var _hover_tween: Tween = null

# Glow animation state
var _glow_time := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_base_scale = scale  # captures 0.03 from scene instance
	set_process(false)
	get_parent().get_parent().add_position(self.position)


func _process(delta: float) -> void:
	_glow_time += delta
	queue_redraw()


func _draw() -> void:
	if not _indicator_active:
		return
	var half_w := 180.0
	var half_h := 320.0
	var rect := Rect2(-half_w, -half_h, half_w * 2.0, half_h * 2.0)
	var glow_alpha := 0.3 + 0.2 * sin(_glow_time * 3.0)
	var glow_color := Color(_indicator_color.r, _indicator_color.g, _indicator_color.b, glow_alpha)
	var line_width := 50.0
	# Draw glow layer
	draw_rect(rect, glow_color, false, line_width + 30.0)
	# Draw solid outline
	draw_rect(rect, _indicator_color, false, line_width)

# Set placement indicator with optional category color
func set_placement_indicator(is_valid: bool, color: Color = COLOR_PLAYER_PATH) -> void:
	_valid_placement = is_valid
	if is_valid:
		_indicator_color = color
	_update_visual()

# Set train indicator with optional category color
func set_train_indicator(is_open: bool, color: Color = COLOR_OPEN_TRAIN) -> void:
	_train_open = is_open
	if is_open:
		_indicator_color = color
	_update_visual()

# Clear all indicators and reset visual state
func clear_indicators() -> void:
	_valid_placement = false
	_train_open = false
	_update_visual()

func _update_visual() -> void:
	var was_active := _indicator_active
	# Only show indicator if this is a valid placement
	# _train_open alone does NOT activate the indicator (empty-hand guard)
	if _valid_placement:
		_indicator_active = true
	else:
		_indicator_active = false
	if not was_active and _indicator_active:
		_glow_time = 0.0
	set_process(_indicator_active)
	if was_active and not _indicator_active:
		# Reset scale when deactivating
		scale = _base_scale
	if was_active != _indicator_active or _indicator_active:
		queue_redraw()


func disable(is_disabled: bool) -> void:
	$Area2D/CollisionShape2D.disabled = is_disabled

# handle placing domino if domino is placed on to path
func _on_Area2D_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			get_parent().get_parent().place_domino(num)


func _on_Area2D_mouse_entered() -> void:
	if not _indicator_active:
		return
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", _base_scale * 1.1, 0.1).set_ease(Tween.EASE_OUT)


func _on_Area2D_mouse_exited() -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "scale", _base_scale, 0.1).set_ease(Tween.EASE_OUT)
