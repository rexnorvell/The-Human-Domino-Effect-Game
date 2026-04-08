# node for characters sitting around game board
extends Node2D

var my_player_id = null

# Glow state (per D-14: pulsing gold glow for active player turn indicator)
var _glow_active := false
var _glow_time := 0.0
var _glow_color := Color(1.0, 0.85, 0.0, 0.7)  # warm gold

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)

func set_active_glow(active: bool) -> void:
	_glow_active = active
	_glow_time = 0.0
	set_process(active)
	queue_redraw()

func _process(delta: float) -> void:
	if _glow_active:
		_glow_time += delta
		queue_redraw()

func _draw() -> void:
	if not _glow_active:
		return
	# Pulsing glow using same sin() pattern as _NextSlotIndicator and Path.gd
	var alpha := 0.3 + 0.2 * sin(_glow_time * 3.0)
	var glow_col := Color(_glow_color.r, _glow_color.g, _glow_color.b, alpha)
	# Draw rounded rect outline around bubble area (local coordinates)
	var rect := Rect2(-45, -55, 90, 110)
	draw_rect(rect, glow_col, false, 4.0)

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
