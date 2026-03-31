# node for characters sitting around game board
extends Node2D

var my_player_id = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func setup_character(player_id):
	my_player_id = player_id
	
	# 1. Update the Face and Body
	if gamestate.body.has(player_id):
		var face_index = gamestate.body[player_id]
		var face_path = "res://UI/sprites/character_sprites/faces/" + str(face_index) + ".png"
		var body_path = "res://UI/sprites/character_sprites/bodies/" + str(face_index) + ".png"
		if ResourceLoader.exists(face_path):
			$face.texture = load(face_path)
		if ResourceLoader.exists(body_path):
			var popup_body = get_node_or_null("Score/Button/Popup/body")
			if popup_body: popup_body.texture = load(body_path)
			
	# 2. Update the Hair
	if gamestate.hair.has(player_id):
		var hair_index = gamestate.hair[player_id]
		
		# Load front hair
		var front_hair_path = "res://UI/sprites/character_sprites/front_hair/" + str(hair_index) + ".png"
		if ResourceLoader.exists(front_hair_path):
			$front_hair.texture = load(front_hair_path)
			var popup_fh = get_node_or_null("Score/Button/Popup/front_hair")
			if popup_fh: popup_fh.texture = load(front_hair_path)
			
		# Load back hair
		var back_hair_path = "res://UI/sprites/character_sprites/back_hair/" + str(hair_index) + ".png"
		if ResourceLoader.exists(back_hair_path):
			$back_hair.texture = load(back_hair_path)
			var popup_bh = get_node_or_null("Score/Button/Popup/back_hair")
			if popup_bh: popup_bh.texture = load(back_hair_path)

	# 3. Update the Clothes
	if gamestate.clothes.has(player_id):
		var clothes_index = gamestate.clothes[player_id]
		var clothes_path = "res://UI/sprites/character_sprites/clothes/" + str(clothes_index) + ".png"
		if ResourceLoader.exists(clothes_path):
			var popup_clothes = get_node_or_null("Score/Button/Popup/clothes")
			if popup_clothes: popup_clothes.texture = load(clothes_path)

# show or hide character stats
func _on_Area2D_mouse_entered() -> void:
	$Score/Button/Popup.visible = true
	
func _on_Area2D_mouse_exited() -> void:
	$Score/Button/Popup.visible = false
