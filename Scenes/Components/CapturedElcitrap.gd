extends RigidBody2D

signal hover_started(sprite: String)
signal hover_ended()

var current_type = null
var original_pos = Vector2(0,0)
var selected = false
var t = 0.0

var anim_table = {"red": "arts", "green": "science", "blue": "humanities"}


func _ready():
	original_pos = self.position

	
func init(type, pos):
	$AnimatedSprite2D.animation = type[0]
	$Label.text = type[1]
	current_type = type
	original_pos = pos
	$AnimatedSprite2D2.animation = anim_table[current_type[0]]


func _on_mouse_entered() -> void:
	hover_started.emit(anim_table[current_type[0]])


func _on_mouse_exited() -> void:
	hover_ended.emit()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var parent = get_parent()
		if not selected:
			if len(parent.selected) >= 5:
				$Deselect.playing = true
				return
			selected = true
			
			# Use set_deferred to safely teleport the physics body without lagging
			set_deferred("position", Vector2(500 + randf_range(-125, 125), 300 + randf_range(-125, 125)))
			
			# Freeze physics math while it's captured to save CPU
			set_deferred("freeze", true) 
			
			# If you have a particle node emitting, uncomment the line below to save GPU!
			# if has_node("Particles2D"): $Particles2D.emitting = false
			
			parent.selected.append(current_type)
			$Select.playing = true
			
		else:
			# It IS already selected, so we are deselecting it.
			selected = false
			
			# Safely teleport it back and turn physics back on
			set_deferred("position", original_pos)
			set_deferred("freeze", false)
			
			# Turn particles back on if you disabled them above
			# if has_node("Particles2D"): $Particles2D.emitting = true
			
			# Find it and remove it safely
			var ind = parent.selected.find(current_type)
			if ind != -1: # Double check it actually exists before removing
				parent.selected.remove_at(ind)
			
			$Deselect.playing = true
