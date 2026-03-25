extends Button
class_name PlayerIconButton

var animated_style: StyleBoxFlat
var border_tween: Tween
var background_tween: Tween
var is_selected: bool = false
const DEFAULT_BACKGROUND_COLOR: Color = Color.WHITE
const DISABLED_BACKGROUND_COLOR: Color = Color.WEB_GRAY
const MAX_BORDER_WIDTH: int = 3
const MIN_BORDER_WIDTH: int = 0

@export var hover_color: Color = Color.html("00af00"):
	set(value):
		hover_color = value
		_update_background_colors()

@export var border_color: Color = Color.html("00af00"):
	set(value):
		border_color = value
		_update_border_colors()


func _ready():
	var base_style = get_theme_stylebox("normal", "Button")
	animated_style = base_style.duplicate()

	animated_style.border_width_left = 0
	animated_style.border_width_right = 0
	animated_style.border_width_top = 0
	animated_style.border_width_bottom = 0

	add_theme_stylebox_override("normal", animated_style)
	add_theme_stylebox_override("hover", animated_style)
	add_theme_stylebox_override("pressed", animated_style)
	add_theme_stylebox_override("focus", animated_style)
	add_theme_stylebox_override("disabled", animated_style)

	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	pressed.connect(_on_pressed)
	
	_update_border_colors()


func _on_hover():
	if !disabled:
		animate_background(hover_color)


func _on_unhover():
	if !disabled:
		animate_background(DEFAULT_BACKGROUND_COLOR)


func _on_focus_entered():
	if !disabled:
		animate_background(hover_color)


func _on_focus_exited():
	if !disabled:
		animate_background(DEFAULT_BACKGROUND_COLOR)

func _update_border_colors():
	if animated_style:
		animated_style.border_color = border_color


func _update_background_colors():
	if animated_style:
		animated_style.bg_color = hover_color


func press():
	_on_pressed()


func _on_pressed():
	if !disabled:
		set_is_selected(true)
		animate_border(MAX_BORDER_WIDTH)
		animate_background(DEFAULT_BACKGROUND_COLOR)


func set_is_selected(selected: bool):
	is_selected = selected
	focus_mode = Control.FOCUS_NONE if is_selected else Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_ARROW if is_selected else Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_IGNORE if is_selected else Control.MOUSE_FILTER_STOP


func get_is_selected() -> bool:
	return is_selected


func set_is_available(available: bool):
	if available:
		animate_border(MIN_BORDER_WIDTH)
		animate_background(DEFAULT_BACKGROUND_COLOR)
		set_is_selected(false)
		disabled = false
	else:
		animate_border(MIN_BORDER_WIDTH)
		animate_background(DISABLED_BACKGROUND_COLOR)
		set_is_selected(true)
		disabled = true


func animate_border(target_width: int):
	if border_tween:
		border_tween.kill()
	
	border_tween = create_tween()
	border_tween.set_trans(Tween.TRANS_CUBIC)
	border_tween.set_ease(Tween.EASE_OUT)
	
	border_tween.tween_method(
		func(value):
			animated_style.border_width_left = value
			animated_style.border_width_right = value
			animated_style.border_width_top = value
			animated_style.border_width_bottom = value,
		animated_style.border_width_left,
		target_width,
		0.3
	)


func animate_background(end_color: Color):
	if background_tween:
		background_tween.kill()
	
	var start_color = animated_style.bg_color
	
	background_tween = create_tween()
	background_tween.set_trans(Tween.TRANS_CUBIC)
	background_tween.set_ease(Tween.EASE_OUT)

	background_tween.tween_method(
		func(value):
			animated_style.bg_color = value,
		start_color,
		end_color,
		0.2
	)
