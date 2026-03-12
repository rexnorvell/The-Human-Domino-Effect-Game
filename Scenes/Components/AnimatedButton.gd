extends Button
class_name AnimatedButton

var animated_style: StyleBoxFlat
var current_tween: Tween
const MAX_BORDER_WIDTH: int = 5
const MIN_BORDER_WIDTH: int = 0

@export var font_color: Color = Color.WHITE:
	set(value):
		font_color = value
		_update_font_colors()

@export var border_color: Color = Color.BLACK:
	set(value):
		border_color = value
		_update_border_colors()

@export var button_is_disabled: bool = false:
	set(value):
		button_is_disabled = value
		disabled = value
		_update_focus()
		_update_cursor()


func _ready():
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	
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

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	
	_update_font_colors()
	_update_border_colors()


func _update_focus():
	focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL


func _update_cursor():
	mouse_default_cursor_shape = (
		Control.CURSOR_ARROW if disabled
		else Control.CURSOR_POINTING_HAND
	)


func _on_hover():
	if !disabled:
		animate_border(MAX_BORDER_WIDTH)


func _on_unhover():
	if !disabled:
		animate_border(MIN_BORDER_WIDTH)


func _on_focus_entered():
	if !disabled:
		animate_border(MAX_BORDER_WIDTH)


func _on_focus_exited():
	if !disabled:
		animate_border(MIN_BORDER_WIDTH)


func animate_border(target_width: int):
	if current_tween:
		current_tween.kill()

	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_CUBIC)
	current_tween.set_ease(Tween.EASE_OUT)

	current_tween.tween_method(
		func(value):
			animated_style.border_width_left = value
			animated_style.border_width_right = value
			animated_style.border_width_top = value
			animated_style.border_width_bottom = value,
		animated_style.border_width_left,
		target_width,
		0.15
	)


func _update_font_colors():
	add_theme_color_override("font_color", font_color)
	add_theme_color_override("font_hover_color", font_color)
	add_theme_color_override("font_pressed_color", font_color)
	add_theme_color_override("font_focus_color", font_color)


func _update_border_colors():
	if animated_style:
		animated_style.border_color = border_color
