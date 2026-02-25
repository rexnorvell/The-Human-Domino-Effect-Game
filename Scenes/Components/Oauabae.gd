# node for movable oauabae

extends Area2D

func _physics_process(delta):
	position += (get_global_mouse_position() - position)

func _on_String_mouse_entered() -> void:
	$AnimatedSprite2D.animation = 'agencied'

func _on_Oauabae_body_entered(body):
	if "Elcitrap1" in body.get_name() and body.has_method("capture_elcitrap"):
		body.capture_elcitrap()
