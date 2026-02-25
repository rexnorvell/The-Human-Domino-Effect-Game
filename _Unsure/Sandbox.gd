extends Node3D

# NOTE: If domino game performance is low, try switching to preload
#var chunk_scene = preload("res://Scenes/Level_5_VirtualWorld/Chunk.tscn")
var chunk_scene = load(ReferenceManager.get_reference("Chunk.tscn"))

var load_radius = 5
@onready var chunks = $Chunks
@onready var player = $Player

var load_thread = Thread.new()

func _ready():
	
	# Player starts at (0,0) but chunks load AROUND player
	# Chunks need to be loaded on negative domain
	var radius_offset = -floor(load_radius/2)

	# Create chunks around the player's initial load radius
	for i in range(radius_offset, load_radius+radius_offset):
		for j in range(radius_offset, load_radius+radius_offset):
			var chunk = chunk_scene.instantiate()
			chunk.set_chunk_position(Vector2(i, j))

			chunks.add_child(chunk)
	
	load_thread.start(Callable(self, "_thread_process").bind(null))

	# Connect signals to handlers
	player.connect("place_block", Callable(self, "_on_Player_place_block"))
	player.connect("break_block", Callable(self, "_on_Player_break_block"))

# Thread process for updating chunks
# Watches if any chunks need to be rerendered and moved
# TODO: [Chunk Loading] Seeding to store any changes
# TODO: [Chunk Loading] Increase amount of threads as needed
func _thread_process(_userdata):
	while(true):
		for c in chunks.get_children():
			# Get chunk position
			var cx = c.chunk_position.x
			var cz = c.chunk_position.y

			# Get player position
			var px = floor(player.position.x / gamestate.DIMENSION.x)
			var pz = floor(player.position.z / gamestate.DIMENSION.z)

			# Locate new position of chunk if outside player view radius
			var new_x = posmod(cx - px + load_radius/2, load_radius) + px - load_radius/2
			var new_z = posmod(cz - pz + load_radius/2, load_radius) + pz - load_radius/2

			# If chunk position needs to be updated
			if (new_x != cx or new_z != cz):
				c.set_chunk_position(Vector2(int(new_x), int(new_z)))
				c.generate()
				c.update()

# TODO: [Optimization] Optimize random access chunk (hashmap?)
func get_chunk(chunk_pos):
	for c in chunks.get_children():
		if c.chunk_position == chunk_pos:
			return c
	return null

# Signal handler for placing block
func _on_Player_place_block(pos, t):
	# Find the chunk in the world
	var cx = int(floor(pos.x / gamestate.DIMENSION.x))
	var cz = int(floor(pos.z / gamestate.DIMENSION.z))

	# Find the block in the chunk
	# Float to int conversion is fine to get array indices
	var bx = posmod(floor(pos.x), gamestate.DIMENSION.x)
	var by = posmod(floor(pos.y), gamestate.DIMENSION.y)
	var bz = posmod(floor(pos.z), gamestate.DIMENSION.z)

	var c = get_chunk(Vector2(cx, cz))
	if c != null:
		c.blocks[bx][by][bz] = t
		c.update()

# Signal handler for breaking block
func _on_Player_break_block(pos):
	# Replace a block with air to break
	_on_Player_place_block(pos, gamestate.AIR)
