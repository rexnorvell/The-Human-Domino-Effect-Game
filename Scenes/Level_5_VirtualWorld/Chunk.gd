@tool
extends StaticBody3D

# Corners of 3D block
const vertices = [
	Vector3(0, 0, 0), # 0
	Vector3(1, 0, 0), # 1
	Vector3(0, 1, 0), # 2
	Vector3(1, 1, 0), # 3
	Vector3(0, 0, 1), # 4
	Vector3(1, 0, 1), # 5
	Vector3(0, 1, 1), # 6
	Vector3(1, 1, 1)  # 7
]

# Block faces derived from indices of the vertices list
const TOP = [2, 3, 7, 6]
const BOTTOM = [0, 4, 5, 1]
const LEFT = [6, 4, 0, 2]
const RIGHT = [3, 1, 5, 7]
const FRONT = [7, 5, 4, 6]
const BACK = [2, 0, 1, 3]

# Array to store all block instances of chunk
var blocks = []

# Variables for block material and texture
var st = SurfaceTool.new()
var mesh = null
var mesh_instance = null

# NOTE: If Virtual World performance is low, try switching to preload
#var material = preload("res://UI/sprites/new_spatialmaterial.tres")
var material = load(ReferenceManager.get_reference("new_spatialmaterial.tres"))

# Global position of chunk
var chunk_position = Vector2(): set = set_chunk_position

# Noise generator for terrain randomization
var noise = FastNoiseLite.new()

func _ready():
	material.albedo_texture.set_flags(2)

	generate()
	update()

# Create all block instances residing within chunk
func generate():
	# Reset blocks and populate chunk with blocks in all dimensions
	blocks = []
	blocks.resize(gamestate.DIMENSION.x)
	for i in range(0, gamestate.DIMENSION.x):
		blocks[i] = []
		blocks[i].resize(gamestate.DIMENSION.y)
		for j in range(0, gamestate.DIMENSION.y):
			blocks[i][j] = []
			blocks[i][j].resize(gamestate.DIMENSION.z)
			for k in range(0, gamestate.DIMENSION.z):
				# Randomize a height for a vertical set of blocks
				var global_pos = chunk_position * \
					Vector2(gamestate.DIMENSION.x, gamestate.DIMENSION.z) + \
					Vector2(i, k)
				# var height = int((noise.get_noise_2dv(global_pos) + 1) / 2 * gamestate.DIMENSION.y)
				var height = 25

				# Create layering for vertical set of blocks
				var block = gamestate.AIR
				if j < height / 2:
					block = gamestate.STONE
				elif j < height:
					block = gamestate.DIRT
				elif j == height:
					block = gamestate.GRASS
				
				blocks[i][j][k] = block

func update():
	if mesh_instance != null:
		mesh_instance.call_deferred("queue_free")
		mesh_instance = null
	
	# Create new mesh instance for textures
	mesh = Mesh.new()
	mesh_instance = MeshInstance3D.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Chunk contains multiple blocks
	# Load all chunk blocks in all dimensions
	for x in gamestate.DIMENSION.x:
		for y in gamestate.DIMENSION.y:
			for z in gamestate.DIMENSION.z:
				create_block(x, y, z)
	
	st.generate_normals(false)
	st.set_material(material)
	st.commit(mesh)
	mesh_instance.set_mesh(mesh)

	add_child(mesh_instance)
	mesh_instance.create_trimesh_collision()
	
	# Make chunk visible when it is finished
	# loading and moving to proper space
	self.visible = true

# No need to render block faces that 
# are hidden within blocks for optimization
func check_transparent(x, y, z):
	if x >= 0 and x < gamestate.DIMENSION.x and \
		y >= 0 and y < gamestate.DIMENSION.y and \
		z >= 0 and z < gamestate.DIMENSION.z:
			return not gamestate.types[blocks[x][y][z]][gamestate.SOLID]
	return true

# Creates block object at position xyz
func create_block(x, y, z):

	# Get what block to render
	var block = blocks[x][y][z]
	if block == gamestate.AIR:
		return

	var block_info = gamestate.types[block]
	
	# Don't render top face if there is block above
	if check_transparent(x, y + 1, z):
		create_face(TOP, x, y, z, block_info[gamestate.TOP])
	
	# Don't render bottom face if there is a block below
	if check_transparent(x, y - 1, z):
		create_face(BOTTOM, x, y, z, block_info[gamestate.BOTTOM])
	
	# Don't render left face if there is a block to the left
	if check_transparent(x - 1, y, z):
		create_face(LEFT, x, y, z, block_info[gamestate.LEFT])
	
	# Don't render right face if there is a block to the right
	if check_transparent(x + 1, y, z):
		create_face(RIGHT, x, y, z, block_info[gamestate.RIGHT])
	
	# Don't render front face if there is a block in front
	if check_transparent(x, y, z + 1):
		create_face(FRONT, x, y, z, block_info[gamestate.FRONT])
	
	# Don't render back face if there is a block behind
	if check_transparent(x, y, z - 1):
		create_face(BACK, x, y, z, block_info[gamestate.BACK])

# Creates faces of block
func create_face(i, x, y, z, texture_atlas_offset):
	var offset = Vector3(x, y, z)

	# Locate all four corners of face
	var a = vertices[i[0]] + offset
	var b = vertices[i[1]] + offset
	var c = vertices[i[2]] + offset
	var d = vertices[i[3]] + offset

	# Convert to a position relative to current block
	var uv_offset = texture_atlas_offset / gamestate.TEXTURE_ATLAS_SIZE
	var height = 1.0 / gamestate.TEXTURE_ATLAS_SIZE.y
	var width = 1.0 / gamestate.TEXTURE_ATLAS_SIZE.x

	# Render on all four corners of face
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, height)
	var uv_c = uv_offset + Vector2(width, height)
	var uv_d = uv_offset + Vector2(width, 0)

	st.add_triangle_fan(([a,b,c]), ([uv_a, uv_b, uv_c]))
	st.add_triangle_fan(([a,c,d]), ([uv_a, uv_c, uv_d]))

# Move a chunk to specific global position
func set_chunk_position(pos):
	chunk_position = pos
	position = Vector3(pos.x, 0, pos.y) * gamestate.DIMENSION

	# Make chunk invisible while it is being moved
	self.visible = false
