extends Camera2D

var dragging: bool = false
var velocity: Vector2 = Vector2.ZERO
var starting_pos: Vector2
var max_x: int
var min_x: int
var max_y: int
var min_y: int

const CENTER_KEY: Key = KEY_A


func _ready() -> void:
	starting_pos = self.global_position
	var viewport_size = get_viewport_rect().size
	var half_width = (viewport_size.x * 0.5) / self.zoom.x
	var half_height = (viewport_size.y * 0.5) / self.zoom.y
	min_x = self.limit_left + half_width
	max_x = self.limit_right - half_width
	min_y = self.limit_top + half_height
	max_y = self.limit_bottom - half_height


func _process(_delta) -> void:
	self.global_position -= velocity
	_clamp_to_bounds()
	velocity = velocity.lerp(Vector2.ZERO, 0.2)


func _clamp_to_bounds() -> void:
	var clamped_x = clamp(self.global_position.x, min_x, max_x)
	var clamped_y = clamp(self.global_position.y, min_y, max_y)
	if clamped_x != self.global_position.x:
		velocity.x = 0
	if clamped_y != self.global_position.y:
		velocity.y = 0
	self.global_position.x = clamped_x
	self.global_position.y = clamped_y


func _input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		velocity = event.relative * self.zoom.x * 0.15
	elif event is InputEventKey and event.pressed and event.keycode == CENTER_KEY:
		dragging = false
		velocity = Vector2.ZERO
		self.global_position = starting_pos


func set_drag(is_dragging: bool) -> void:
	self.dragging = is_dragging
