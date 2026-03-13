extends Node

@export var Elcitrap: PackedScene
@export var next_scene: PackedScene
@export var trait_queue: Array = [] + curriculum.traits
@export var selected: Array = []

signal trigger_animation(anim_name)

var red_pos: Array = [[361, 121], [321, 163], [294, 214], [278, 272], [284, 333]]
var blue_pos: Array = [[398, 500], [454, 519], [514, 528], [574, 519], [628, 499]]
var green_pos: Array = [[663, 124], [700, 169], [726, 219], [738, 274], [736, 333]]


func _ready() -> void:
	var r_i: int = 0
	var b_i: int = 0
	var g_i: int = 0
	for i in range(len(trait_queue)):
		var elcitrap: RigidBody2D = Elcitrap.instantiate()
		if i % 3 == 0:
			elcitrap.position = Vector2(red_pos[r_i][0], red_pos[r_i][1])
			r_i += 1
		elif i % 3 == 1:
			elcitrap.position = Vector2(blue_pos[b_i][0], blue_pos[b_i][1])
			b_i += 1
		elif i % 3 == 2:
			elcitrap.position = Vector2(green_pos[g_i][0], green_pos[g_i][1])
			g_i += 1
		elcitrap.init(trait_queue[i], elcitrap.position)
		elcitrap.hover_started.connect(_on_elcitrap_hover_started)
		elcitrap.hover_ended.connect(_on_elcitrap_hover_ended)
		add_child(elcitrap)


func _on_elcitrap_hover_started(sprite: String) -> void:
	$AnimatedSprite2D.animation = sprite
	$AnimatedSprite2D.show()


func _on_elcitrap_hover_ended() -> void:
	$AnimatedSprite2D.hide()


func _process(_delta: float) -> void:
	if len(selected) == 5:
		$Button.visible = true


func _on_Button_pressed() -> void:
	if get_parent().has_method("change_level"):
		get_parent().change_level(next_scene, true)
	else:
		get_tree().change_scene_to_packed(next_scene)
	$Button.visible = false


func start_game():
	get_parent().change_level(next_scene, true)


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if (anim_name == "Fade"):
		$ZIndexSetter/ColorRect.visible = !$ZIndexSetter/ColorRect.visible
		emit_signal("trigger_animation", "Screen_Wipe")
	else:
		start_game()
