extends RigidBody2D


func _on_String_mouse_entered() -> void:
	$Sprite2D/AnimationPlayer.play("Out")
	await $Sprite2D/AnimationPlayer.animation_finished
	queue_free()
	get_parent().get_node('Next').start()
