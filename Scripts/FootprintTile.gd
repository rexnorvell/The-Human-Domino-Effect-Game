extends Area2D

# Declare member variables here:
var footprint_num = 0
var round_num = 0

# warning-ignore:shadowed_variable
# warning-ignore:shadowed_variable
static func convert_to_index(footprint_num: int, round_num: int) -> int:
	return footprint_num + gamestate.tiles_per_round * round_num

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _init(index: int = 0, in_ring: bool = false) -> void:
	# SET MEMBERS
	self.footprint_num = index % gamestate.tiles_per_round
# warning-ignore:integer_division
	self.round_num = index / gamestate.tiles_per_round
	
	var ShapeSprite = Sprite2D.new()
	var RoundSprite = Sprite2D.new()
	var NumberSprite = Sprite2D.new()
	
	add_child(ShapeSprite)
	add_child(RoundSprite)
	add_child(NumberSprite)
	
	# SETTING FOOTPRINT SHAPE
	ShapeSprite.texture = shape_sprites[self.shape_index()]
	
	# SETTING FOOTPRINT COLLISION
	if in_ring:
		var collision2d = CollisionPolygon2D.new()
		collision2d.polygon = shape_collisions[self.shape_index()]
		if connect("mouse_entered", Callable(self, "_mouse_entered")):
			print("Connect failed for mouse_entered")
		if connect("mouse_exited", Callable(self, "_mouse_exited")):
			print("Connect failed for mouse_exited")
		add_child(collision2d)
	
	# SETTING FOOTPRINT COLOR
	self.modulate = tile_colors[self.color_index()]
	# SETTING FOOTPRINT ROUND TOKEN
	RoundSprite.texture = round_sprites[self.round_num]
	# SETTING FOOTPRINT NUMBER TOKEN
	NumberSprite.texture = number_sprites[self.footprint_num]
	
	# flip tile horizontally if 2nd of every 3 tiles in outer ring
	var flipH = self.in_outer_ring_layer() and self.tile_index() % 3 == 1
	ShapeSprite.flip_h = flipH
	RoundSprite.flip_h = flipH
	NumberSprite.flip_h = flipH
	
	# scale appropriately if meant to be in ring:
	if in_ring: self.scale = shape_scales_for_ring[self.shape_index()]
	else: self.scale = default_size

func tile_index(): return convert_to_index(self.footprint_num, self.round_num)
	
func in_outer_ring_layer() -> bool: return self.tile_index() < gamestate.num_outer_tiles

func shape_index():
	if self.in_outer_ring_layer(): # outer ring layer has a shape order pattern:
		# use shape 0 for every third tile
		return 0 if self.tile_index() % 3 == 0 else 1
	# inner ring layer has a different shape order pattern:
	# alternate beteen shape 0 and shape 2
	return 2 * (self.tile_index() % 2)
	
func color_index():
	# both ring layers have a similar order of 6 colors, but the inner layer uses
	# darker variants (which are indexed 6-11)
	return (self.tile_index() % 6) + (0 if self.in_outer_ring_layer() else 6)

# Functions related to the hitbox of this footprint tile
func _mouse_entered() -> void:
	self.scale += size_increase
func _mouse_exited() -> void:
	self.scale = shape_scales_for_ring[self.shape_index()]
	
signal display_footprint(round_number, footprint_number)
func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		emit_signal("display_footprint", self.round_num, self.footprint_num)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

# CONST VARIABLES (note: order matters within these arrays)
const size_increase = Vector2(0.2, 0.2)
const default_size = Vector2(2, 2)

# Load sprites for footprint tile shapes
# NOTE: If domino game performance is low, try switching to preload
"""
const shape_sprites = [
	preload("res://UI/sprites/footprint_tiles/ConvexHexagon1.png"),
	preload("res://UI/sprites/footprint_tiles/Trapezoid.png"),
	preload("res://UI/sprites/footprint_tiles/ConvexHexagon2.png")
]
"""
var shape_sprites = [
	load(ReferenceManager.get_reference("ConvexHexagon1.png")),
	load(ReferenceManager.get_reference("Trapezoid.png")),
	load(ReferenceManager.get_reference("ConvexHexagon2.png"))
]
# const that marks the shape of the collision box for each footprint tile sprite
# each element is a PoolVector2Array which contain coordinates for a CollisionPolygon2D Node
# this array is ordered to correspond to the shape_sprites const above.
const shape_collisions = [
	[
		Vector2(67, 82),
		Vector2(70, -57),
		Vector2(9, -87),
		Vector2(-6, -87),
		Vector2(-37, -60),
		Vector2(-70, -40),
		Vector2(-68, 99),
		Vector2(0, 44)
	],
	[
		Vector2(70, -87),
		Vector2(-71, -27),
		Vector2(-55, 45),
		Vector2(55, 89)
	],
	[
		Vector2(-49, 86),
		Vector2(-73, -33),
		Vector2(1, -89),
		Vector2(71, -47),
		Vector2(42, 92),
		Vector2(-9, 58)
	]
]

const shape_scales_for_ring = [
	Vector2(1.0, 1.0),
	Vector2(0.8, 0.8),
	Vector2(1.2, 1.2)
]
# Load sprites for footprint tile rounds (in round order)
# NOTE: If domino game performance is low, try switching to preload
"""
const round_sprites = [
	preload("res://UI/sprites/footprint_tiles/Campfire.png"),
	preload("res://UI/sprites/footprint_tiles/Dog.png"),
	preload("res://UI/sprites/footprint_tiles/Bowl.png"),
	preload("res://UI/sprites/footprint_tiles/Ship.png"),
	preload("res://UI/sprites/footprint_tiles/Book.png"),
	preload("res://UI/sprites/footprint_tiles/Car.png")
]
"""
var round_sprites = [
	load(ReferenceManager.get_reference("Campfire.png")),
	load(ReferenceManager.get_reference("Dog.png")),
	load(ReferenceManager.get_reference("Bowl.png")),
	load(ReferenceManager.get_reference("Ship.png")),
	load(ReferenceManager.get_reference("Book.png")),
	load(ReferenceManager.get_reference("Car.png")),
]
# Load sprites for footprint tile numbers
# NOTE: If domino game performance is low, try switching to preload
"""
const number_sprites = [
	null, # no number needed if footprint tile 0
	preload("res://UI/sprites/footprint_tiles/Domino1.png"),
	preload("res://UI/sprites/footprint_tiles/Domino2.png"),
	preload("res://UI/sprites/footprint_tiles/Domino3.png"),
	preload("res://UI/sprites/footprint_tiles/Domino4.png"),
	preload("res://UI/sprites/footprint_tiles/Domino5.png"),
	preload("res://UI/sprites/footprint_tiles/Domino6.png"),
	preload("res://UI/sprites/footprint_tiles/Domino7.png"),
	preload("res://UI/sprites/footprint_tiles/Domino8.png"),
	preload("res://UI/sprites/footprint_tiles/Domino9.png"),
]
"""
var number_sprites = [
	null, # no number needed if footprint tile 0
	load(ReferenceManager.get_reference("Domino1.png")),
	load(ReferenceManager.get_reference("Domino2.png")),
	load(ReferenceManager.get_reference("Domino3.png")),
	load(ReferenceManager.get_reference("Domino4.png")),
	load(ReferenceManager.get_reference("Domino5.png")),
	load(ReferenceManager.get_reference("Domino6.png")),
	load(ReferenceManager.get_reference("Domino7.png")),
	load(ReferenceManager.get_reference("Domino8.png")),
	load(ReferenceManager.get_reference("Domino9.png")),
]
# colors for footprint tiles in cycle order
const tile_colors = [
	# used for outer ring of footprint tiles
	Color8(255, 253 ,190), # light yellow
	Color8(175, 200, 160), # light green
	Color8(166, 206, 236), # light blue
	Color8(201, 136, 171), # light purple
	Color8(255, 157, 141), # light pink
	Color8(255, 219, 143), # light orange
	# used for inner ring of footprint tiles
	Color8(255, 253 ,137), # darker yellow
	Color8(146, 180, 125), # darker green
	Color8(129, 186, 228), # darker blue
	Color8(181, 093, 140), # darker purple
	Color8(255, 116, 092), # darker pink
	Color8(255, 215, 139)  # darker orange
]
