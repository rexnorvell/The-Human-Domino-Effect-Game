# node for characters sitting around game board
extends Node2D

var my_player_id = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# DominoWorld.gd will call this when it creates the bubble to apply customization
func setup_character(player_id):
	my_player_id = player_id
	
	# 1. Update the Face
	if gamestate.body.has(player_id):
		var face_index = gamestate.body[player_id]
		var face_path = "res://UI/sprites/character_sprites/faces/" + str(face_index) + ".png"
		if ResourceLoader.exists(face_path):
			$face.texture = load(face_path)
			
	# 2. Update the Hair
	if gamestate.hair.has(player_id):
		var hair_index = gamestate.hair[player_id]
		
		# Load front hair
		var front_hair_path = "res://UI/sprites/character_sprites/front_hair/" + str(hair_index) + ".png"
		if ResourceLoader.exists(front_hair_path):
			$front_hair.texture = load(front_hair_path)
			
		# Load back hair
		var back_hair_path = "res://UI/sprites/character_sprites/back_hair/" + str(hair_index) + ".png"
		if ResourceLoader.exists(back_hair_path):
			$back_hair.texture = load(back_hair_path)

# show or hide character stats
func _on_Area2D_mouse_entered() -> void:
	$Score/Button/Popup.visible = true
	
func _on_Area2D_mouse_exited() -> void:
	$Score/Button/Popup.visible = false
