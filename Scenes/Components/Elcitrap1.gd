# node for moving elcitrap wave

extends RigidBody2D


# Declare member variables here. Examples:
@export var min_speed = 150  # Minimum speed range.
@export var max_speed = 250  # Maximum speed range.

var current_type = null
var captured = false
var end_pos = null 

var t = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func init(type):
	$AnimatedSprite2D.animation = type[0]
	$Label.text = type[1]
	current_type = type
	if len(type) > 2:
		end_pos = type[2]
	
# recycle elcitrap into queue when it leaves the screen
func _on_visibility_notifier_2d_screen_exited():
	get_parent().trait_queue.append(current_type)
	queue_free()

# if elcitrap has been captured, play captured animation
func _physics_process(delta):
	if captured:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.animation = "static_" + current_type[0]
		$AnimatedSprite2D.scale.x = 0.3
		$Label.visible = true
		self.rotation = 0
		self.linear_velocity = Vector2(0, 0)
		
		t += delta * 0.05
		
		self.position = self.position.lerp(Vector2(end_pos[0], end_pos[1]), t)

# Handle mouse input to capture the elcitrap
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		capture_elcitrap()

# Captures an elcitrap
func capture_elcitrap() -> void:
	if not captured:
		get_parent().total_captured += 1
	captured = true


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	get_parent().trait_queue.append(current_type)
	queue_free()
