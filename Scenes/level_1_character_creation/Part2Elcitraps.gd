extends Node

@export var Elcitrap: PackedScene
@export var next_scene: PackedScene
@export var total_captured: int = 0
@export var trait_queue = [] + curriculum.traits


func _ready():
	for i in range(15):
		trait_queue[i].append([i*60 + 100, 550])
	randomize()
	new_game()


func new_game():
	$ElcitrapTimer.start()


func _on_ElcitrapTimer_timeout():
	if len(trait_queue) > 0:
		$EPath/EPathFollow.progress = randi()
		var elcitrap = Elcitrap.instantiate()
		elcitrap.init(trait_queue[0])
		trait_queue.pop_front()
		add_child(elcitrap)
		var direction = $EPath/EPathFollow.rotation + PI / 2
		elcitrap.position = $EPath/EPathFollow.position
		direction += randf_range(-PI / 4, PI / 4)
		elcitrap.rotation = direction
		elcitrap.linear_velocity = Vector2(randf_range(elcitrap.min_speed, elcitrap.max_speed), 0)
		elcitrap.linear_velocity = elcitrap.linear_velocity.rotated(direction)


func _process(_delta: float) -> void:
	if total_captured == 15:
		$EndTimer.start()
		total_captured = 16


func _on_EndTimer_timeout() -> void:
	get_parent().change_level(next_scene, true)
