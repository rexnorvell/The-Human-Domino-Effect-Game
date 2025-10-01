# node for elcitrap in elcitrap selection scene

extends RigidBody2D

func init(type):
	$AnimatedSprite2D.animation = type[0]
	$Label.text = type[1]
	$Popup/Label.text = type[1]
