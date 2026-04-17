extends Sprite2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var time = 0
@onready var n = (get_material().get_shader_parameter("noise") as NoiseTexture2D)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time += delta * 75
	var noise_value = n.noise.get_noise_1d(time)
	$PointLight2D.scale = Vector2(1.5 + noise_value / 3, 1.5 + noise_value / 3)
