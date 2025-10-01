extends CharacterBody2D

#added in Fall 2024

#variables to help with player movement
var direction : Vector2 = Vector2()

func read_input():
	#will modify vector(s) based on direction input
	velocity = Vector2()
	
	if Input.is_action_pressed("Up"):
		velocity.y -= 1
		direction = Vector2(0, -1)
		
	if Input.is_action_pressed("Down"):
		velocity.y += 1
		direction = Vector2(0, 1)
		
	if Input.is_action_pressed("Left"):
		velocity.x -= 1
		direction = Vector2(-1, 0)
		
	if Input.is_action_pressed("Right"):
		velocity.x += 1
		direction = Vector2(1, 0)
		
	#to make sure the player's speed is normal when going in odd directions (diagonally)
	velocity = velocity.normalized() * 200
	move_and_slide()

#needed for maintaining collision control with objects in the level
func _physics_process(delta):
	read_input()
