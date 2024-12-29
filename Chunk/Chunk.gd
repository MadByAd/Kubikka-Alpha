extends Spatial
tool

enum {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK
}


const VERTICES: Array = [
	Vector3(0, 0, 0), #0,
	Vector3(1, 0, 0), #1,
	Vector3(0, 1, 0), #2,
	Vector3(1, 1, 0), #3,
	Vector3(0, 0, 1), #4,
	Vector3(1, 0, 1), #5,
	Vector3(0, 1, 1), #6,
	Vector3(1, 1, 1), #7,
]
const FACES: Dictionary = {
	TOP:	 [2, 3, 7, 6],
	BOTTOM:	 [0, 4, 5, 1],
	LEFT:	 [6, 4, 0, 2],
	RIGHT:	 [3, 1, 5, 7],
	FRONT:	 [7, 5, 4, 6],
	BACK:	 [2, 0, 1, 3],
}
const AO_TOP: Dictionary = {
	"X":	 Vector2(0, 0),
	"-X":	 Vector2(2, 0),
	"Z":	 Vector2(3, 0),
	"-Z":	 Vector2(1, 0),
}


var blocks: Array = []
var blocks_cache: Array = []
var faces: Array = []
var st: SurfaceTool = SurfaceTool.new()
var lst: SurfaceTool = SurfaceTool.new()
var aost: SurfaceTool = SurfaceTool.new()
var caost: SurfaceTool = SurfaceTool.new()
var mesh: Mesh = null
var mesh_ao: Mesh = null
var mesh_cao: Mesh = null
var mesh_liquid: Mesh = null
var mesh_instance: MeshInstance = null
var mesh_ao_instance: MeshInstance = null
var mesh_cao_instance: MeshInstance = null
var mesh_liquid_instance: MeshInstance = null
var material = preload("res://TextureBlockAtlas.tres")
var material_ao = preload("res://TextureAO.tres")
var material_liquid = preload("res://TextureLiquidAtlasShader.tres")
var generated: bool = false
var has_liquid: bool = false
var has_faces: bool = false
var has_ao: bool = false
var has_cao: bool = false
var chunk_position: Vector3 = Vector3() setget set_chunk_position


func _ready():
	
	
	material.albedo_texture.set_flags(2)
	GameData.spawned_chunk += 1
	self.visible = true


func reset_cache():
	
	
	blocks_cache = []
	blocks_cache.resize(GameData.CHUNK_DIMENSION.x)
	for i in range(0, GameData.CHUNK_DIMENSION.x):
		
		blocks_cache[i] = []
		blocks_cache[i].resize(GameData.CHUNK_DIMENSION.y)
		for j in range(0, GameData.CHUNK_DIMENSION.y):
			
			blocks_cache[i][j] = []
			blocks_cache[i][j].resize(GameData.CHUNK_DIMENSION.z)
			for k in range(0, GameData.CHUNK_DIMENSION.z):
				
				blocks_cache[i][j][k] = null


func generate():
	
	
	generated = true
	
	var chunk = ChunkData.load_chunk(chunk_position)
	if chunk != null:
		blocks = chunk
		reset_cache()
		return
	
	
	blocks = []
	blocks_cache = []
	blocks.resize(GameData.CHUNK_DIMENSION.x)
	blocks_cache.resize(GameData.CHUNK_DIMENSION.x)
	for i in range(0, GameData.CHUNK_DIMENSION.x):
		
		blocks[i] = []
		blocks[i].resize(GameData.CHUNK_DIMENSION.y)
		blocks_cache[i] = []
		blocks_cache[i].resize(GameData.CHUNK_DIMENSION.y)
		for j in range(0, GameData.CHUNK_DIMENSION.y):
			
			blocks[i][j] = []
			blocks[i][j].resize(GameData.CHUNK_DIMENSION.z)
			blocks_cache[i][j] = []
			blocks_cache[i][j].resize(GameData.CHUNK_DIMENSION.z)
			for k in range(0, GameData.CHUNK_DIMENSION.z):
				
				var block = GameData.BLOCKS.AIR
				
				if j == 5:
					block = GameData.BLOCKS.GRASS
#					block = GameData.BLOCKS.SAND
#					block = GameData.BLOCKS.WATER
				elif j < 5:
					block = GameData.BLOCKS.DIRT
#					block = GameData.BLOCKS.SAND
				
				if translation.y < 0:
					block = GameData.BLOCKS.STONE
				if translation.y >= GameData.CHUNK_DIMENSION.y:
					block = GameData.BLOCKS.AIR
				
				blocks[i][j][k] = block
				blocks_cache[i][j][k] = null


func update():
	
	
	has_faces = false
	has_liquid = false
	has_ao = false
	has_cao = false
	
	# Unload the mesh
	if mesh_instance != null:
		mesh_instance.call_deferred("queue_free")
		mesh_instance = null

	if mesh_liquid_instance != null:
		mesh_liquid_instance.call_deferred("queue_free")
		mesh_liquid_instance = null

	if mesh_ao_instance != null:
		mesh_ao_instance.call_deferred("queue_free")
		mesh_ao_instance = null
		mesh_cao_instance.call_deferred("queue_free")
		mesh_cao_instance = null
	
	mesh = Mesh.new()
	mesh_liquid = Mesh.new()
	mesh_instance = MeshInstance.new()
	mesh_liquid_instance = MeshInstance.new()
	
	if GameData.enable_voxel_ao:
		mesh_ao = Mesh.new()
		mesh_cao = Mesh.new()
		mesh_ao_instance = MeshInstance.new()
		mesh_cao_instance = MeshInstance.new()
	
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	lst.begin(Mesh.PRIMITIVE_TRIANGLES)
	aost.begin(Mesh.PRIMITIVE_TRIANGLES)
	caost.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in GameData.CHUNK_DIMENSION.x:
		for y in GameData.CHUNK_DIMENSION.y:
			for z in GameData.CHUNK_DIMENSION.z:
				create_block(x, y, z)
	
	if has_faces:
		
		st.call_deferred("generate_normals", false)
		st.call_deferred("set_material", material)
		st.call_deferred("commit", mesh)
		mesh_instance.set_deferred("mesh", mesh)
		
		call_deferred("add_child", mesh_instance)
		mesh_instance.call_deferred("create_trimesh_collision")
	
	if has_liquid:
		
		lst.call_deferred("generate_normals", false)
		lst.call_deferred("set_material", material_liquid)
		lst.call_deferred("commit", mesh_liquid)
		mesh_liquid_instance.set_deferred("mesh", mesh_liquid)
		
		call_deferred("add_child", mesh_liquid_instance)
		mesh_liquid_instance.call_deferred("create_trimesh_collision")
	
	if GameData.enable_voxel_ao and has_faces:
		
		if has_ao:
			
			aost.call_deferred("generate_normals", false)
			aost.call_deferred("set_material", material_ao)
			aost.call_deferred("commit", mesh_ao)
			mesh_ao_instance.set_deferred("mesh", mesh_ao)
			mesh_ao_instance.set_deferred("cast_shadow", false)
			
			call_deferred("add_child", mesh_ao_instance)
		
		if has_cao:
			
			caost.call_deferred("generate_normals", false)
			caost.call_deferred("set_material", material_ao)
			caost.call_deferred("commit", mesh_cao)
			mesh_cao_instance.set_deferred("mesh", mesh_cao)
			mesh_cao_instance.set_deferred("cast_shadow", false)
			
			call_deferred("add_child", mesh_cao_instance)
	
	ChunkData.store_chunk(chunk_position, blocks)
	GameData.updated_chunk += 1


func check_transparency(x: int, y: int, z: int, property: int = GameData.PROPERTY.SOLID):
	
	
	if (
		x >= 0 and x < GameData.CHUNK_DIMENSION.x and
		y >= 0 and y < GameData.CHUNK_DIMENSION.y and
		z >= 0 and z < GameData.CHUNK_DIMENSION.z
	):
		return not GameData.TYPES[blocks[x][y][z]][property]
	
	if not GameData.enable_seamless_chunk_mesh:
		return true
	
	var position = Vector3(x, y, z)
	var neighboring_chunk_position = chunk_position
	
	if position.x >= GameData.CHUNK_DIMENSION.x:
		position.x = 0
		neighboring_chunk_position.x += 1
	elif position.x < 0:
		position.x = (GameData.CHUNK_DIMENSION.x - 1)
		neighboring_chunk_position.x -= 1
	
	if position.y >= GameData.CHUNK_DIMENSION.y:
		position.y = 0
		neighboring_chunk_position.y += 1
	elif position.y < 0:
		position.y = (GameData.CHUNK_DIMENSION.x - 1)
		neighboring_chunk_position.y -= 1
	
	if position.z >= GameData.CHUNK_DIMENSION.z:
		position.z = 0
		neighboring_chunk_position.z += 1
	elif position.z < 0:
		position.z = (GameData.CHUNK_DIMENSION.x - 1)
		neighboring_chunk_position.z -= 1
	
	var neighboring_chunk = str(neighboring_chunk_position)
	
	if get_parent().has_node(neighboring_chunk):
		return get_parent().get_node(neighboring_chunk).check_transparency_from_neighbor(position, property)
	if property == GameData.PROPERTY.LIQUID:
		return false
	return true


func check_transparency_from_neighbor(position: Vector3, property: int):
	
	
	if blocks.empty():
		return true
	
	return not GameData.TYPES[blocks[position.x][position.y][position.z]][property]


func create_block(x: int, y: int, z: int):
	
	
	var face_created = false
	var block_type = blocks[x][y][z]
	if block_type == GameData.BLOCKS.AIR:
		return
	
	var block_info = GameData.TYPES[block_type]
	var property = GameData.PROPERTY.SOLID
	
	if blocks_cache[x][y][z] != null:
		for face in blocks_cache[x][y][z]:
			create_face_cache(face, x, y, z, blocks_cache[x][y][z][face])
		return
	
	if not block_info[GameData.PROPERTY.SOLID]:
		
		if block_info[GameData.PROPERTY.TRANSPARENT]:
			
			property = GameData.PROPERTY.TRANSPARENT
			
		elif block_info[GameData.PROPERTY.LIQUID]:
			
			property = GameData.PROPERTY.LIQUID
			
			if check_transparency(x, y + 1, z, property):
				create_face_liquid(TOP, x, y, z, block_info[GameData.PROPERTY.TOP])
				face_created = true
			if check_transparency(x, y - 1, z, property):
				create_face_liquid(BOTTOM, x, y, z, block_info[GameData.PROPERTY.BOTTOM])
				face_created = true
			
			if check_transparency(x - 1, y, z, property):
				create_face_liquid(LEFT, x, y, z, block_info[GameData.PROPERTY.LEFT])
				face_created = true
			if check_transparency(x + 1, y, z, property):
				create_face_liquid(RIGHT, x, y, z, block_info[GameData.PROPERTY.RIGHT])
				face_created = true
			
			if check_transparency(x, y, z + 1, property):
				create_face_liquid(FRONT, x, y, z, block_info[GameData.PROPERTY.FRONT])
				face_created = true
			if check_transparency(x, y, z - 1, property):
				create_face_liquid(BACK, x, y, z, block_info[GameData.PROPERTY.BACK])
				face_created = true
			
			if not face_created:
				blocks_cache[x][y][z] = {}
			return
	
	if check_transparency(x, y + 1, z, property):
		create_face(TOP, x, y, z, block_info[GameData.PROPERTY.TOP], property)
		face_created = true
	if check_transparency(x, y - 1, z, property):
		create_face(BOTTOM, x, y, z, block_info[GameData.PROPERTY.BOTTOM], property)
		face_created = true
	
	if check_transparency(x - 1, y, z, property):
		create_face(LEFT, x, y, z, block_info[GameData.PROPERTY.LEFT], property)
		face_created = true
	if check_transparency(x + 1, y, z, property):
		create_face(RIGHT, x, y, z, block_info[GameData.PROPERTY.RIGHT], property)
		face_created = true
	
	if check_transparency(x, y, z + 1, property):
		create_face(FRONT, x, y, z, block_info[GameData.PROPERTY.FRONT], property)
		face_created = true
	if check_transparency(x, y, z - 1, property):
		create_face(BACK, x, y, z, block_info[GameData.PROPERTY.BACK], property)
		face_created = true
	
	if not face_created:
		blocks_cache[x][y][z] = {}


func create_face_liquid(face: int, x: int, y: int, z: int, texture_coordinate):
	
	
	has_liquid = true
	
	var offset = Vector3(x, y, z)
	var i = FACES[face]
	var a = VERTICES[i[0]] + offset
	var b = VERTICES[i[1]] + offset
	var c = VERTICES[i[2]] + offset
	var d = VERTICES[i[3]] + offset
	
	var uv_offset = texture_coordinate / GameData.BLOCK_ATLAS_SIZE
	var uv_height = 1.0 / GameData.BLOCK_ATLAS_SIZE.y
	var uv_width = 1.0 / GameData.BLOCK_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, uv_height)
	var uv_c = uv_offset + Vector2(uv_width, uv_height)
	var uv_d = uv_offset + Vector2(uv_width, 0)
	
	lst.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
	lst.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
	
	if GameData.enable_chunk_update_cache:
		if blocks_cache[x][y][z] == null:
			blocks_cache[x][y][z] = {}
		blocks_cache[x][y][z][face] = {}
		blocks_cache[x][y][z][face]["is_liquid"] = true
		blocks_cache[x][y][z][face]["texture_coordinate"] = texture_coordinate


func create_face_cache(face: int, x: int, y: int, z: int, cache_data: Dictionary):
	
	
	if cache_data["is_liquid"]:
		create_face_liquid(face, x, y, z, cache_data["texture_coordinate"])
		return
	
	has_faces = true
	
	var offset = Vector3(x, y, z)
	var i = FACES[face]
	var a = VERTICES[i[0]] + offset
	var b = VERTICES[i[1]] + offset
	var c = VERTICES[i[2]] + offset
	var d = VERTICES[i[3]] + offset
	
	var uv_offset = cache_data["texture_coordinate"] / GameData.BLOCK_ATLAS_SIZE
	var uv_height = 1.0 / GameData.BLOCK_ATLAS_SIZE.y
	var uv_width = 1.0 / GameData.BLOCK_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, uv_height)
	var uv_c = uv_offset + Vector2(uv_width, uv_height)
	var uv_d = uv_offset + Vector2(uv_width, 0)
	
	st.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
	st.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
	
	if not GameData.enable_voxel_ao:
		return
	
	uv_height = 1.0 / GameData.AO_ATLAS_SIZE.y
	uv_width = 1.0 / GameData.AO_ATLAS_SIZE.x
	
	uv_offset = cache_data["side_ao"]
	
	if uv_offset != null:
		
		uv_offset /= GameData.AO_ATLAS_SIZE
		uv_a = uv_offset + Vector2(0, 0)
		uv_b = uv_offset + Vector2(0, uv_height)
		uv_c = uv_offset + Vector2(uv_width, uv_height)
		uv_d = uv_offset + Vector2(uv_width, 0)
		
		aost.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
		aost.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
		has_ao = true
	
	uv_offset = cache_data["corner_ao"]
	
	if uv_offset != null:
		
		uv_offset /= GameData.AO_ATLAS_SIZE
		uv_a = uv_offset + Vector2(0, 0)
		uv_b = uv_offset + Vector2(0, uv_height)
		uv_c = uv_offset + Vector2(uv_width, uv_height)
		uv_d = uv_offset + Vector2(uv_width, 0)
		
		caost.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
		caost.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
		has_cao = true


func create_face(face: int, x: int, y: int, z: int, texture_coordinate, property: int):
	
	
	has_faces = true
	
	if GameData.enable_chunk_update_cache:
		if blocks_cache[x][y][z] == null:
			blocks_cache[x][y][z] = {}
		blocks_cache[x][y][z][face] = {}
		blocks_cache[x][y][z][face]["is_liquid"] = false
		blocks_cache[x][y][z][face]["texture_coordinate"] = texture_coordinate
	
	var offset = Vector3(x, y, z)
	var i = FACES[face]
	var a = VERTICES[i[0]] + offset
	var b = VERTICES[i[1]] + offset
	var c = VERTICES[i[2]] + offset
	var d = VERTICES[i[3]] + offset
	
	var uv_offset = texture_coordinate / GameData.BLOCK_ATLAS_SIZE
	var uv_height = 1.0 / GameData.BLOCK_ATLAS_SIZE.y
	var uv_width = 1.0 / GameData.BLOCK_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, uv_height)
	var uv_c = uv_offset + Vector2(uv_width, uv_height)
	var uv_d = uv_offset + Vector2(uv_width, 0)
	
	st.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
	st.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
	
	if property != GameData.PROPERTY.SOLID:
		blocks_cache[x][y][z][face]["side_ao"] = null
		blocks_cache[x][y][z][face]["corner_ao"] = null
		return
	if not GameData.enable_voxel_ao:
		blocks_cache[x][y][z][face]["side_ao"] = null
		blocks_cache[x][y][z][face]["corner_ao"] = null
		return
	
	uv_height = 1.0 / GameData.AO_ATLAS_SIZE.y
	uv_width = 1.0 / GameData.AO_ATLAS_SIZE.x
	
	var z_plus: bool
	var z_min: bool
	var x_plus: bool
	var x_min: bool
	
	if face == TOP:
		
		z_plus = !check_transparency(x, y + 1, z + 1)
		z_min  = !check_transparency(x, y + 1, z - 1)
		x_plus = !check_transparency(x + 1, y + 1, z)
		x_min  = !check_transparency(x - 1, y + 1, z)
		
	elif face == BOTTOM:
		
		x_plus = !check_transparency(x, y - 1, z + 1)
		x_min  = !check_transparency(x, y - 1, z - 1)
		z_plus = !check_transparency(x + 1, y - 1, z)
		z_min  = !check_transparency(x - 1, y - 1, z)
		
	elif face == LEFT:
		
		z_min  = !check_transparency(x - 1, y, z + 1)
		z_plus = !check_transparency(x - 1, y, z - 1)
		x_min  = !check_transparency(x - 1, y + 1, z)
		x_plus = !check_transparency(x - 1, y - 1, z)
		
	elif face == RIGHT:
		
		z_plus = !check_transparency(x + 1, y, z + 1)
		z_min  = !check_transparency(x + 1, y, z - 1)
		x_min  = !check_transparency(x + 1, y + 1, z)
		x_plus = !check_transparency(x + 1, y - 1, z)
		
	elif face == FRONT:
		
		x_min  = !check_transparency(x, y + 1, z + 1)
		x_plus = !check_transparency(x, y - 1, z + 1)
		z_min  = !check_transparency(x + 1, y, z + 1)
		z_plus = !check_transparency(x - 1, y, z + 1)
		
	elif face == BACK:
		
		x_min  = !check_transparency(x, y + 1, z - 1)
		x_plus = !check_transparency(x, y - 1, z - 1)
		z_plus = !check_transparency(x + 1, y, z - 1)
		z_min  = !check_transparency(x - 1, y, z - 1)
	
	var ao_sides: Dictionary = createAmbientOnSide(x_min, x_plus, z_min, z_plus)
	
	var corner_ao: bool = ao_sides["corner_ao"]
	var q1_ao: bool = ao_sides["q1_ao"]
	var q2_ao: bool = ao_sides["q2_ao"]
	var q3_ao: bool = ao_sides["q3_ao"]
	var q4_ao: bool = ao_sides["q4_ao"]
	uv_offset = ao_sides["uv_offset"]
	
	if GameData.enable_chunk_update_cache:
		blocks_cache[x][y][z][face]["side_ao"] = uv_offset
	
	if uv_offset != null:
		
		uv_offset /= GameData.AO_ATLAS_SIZE
		uv_a = uv_offset + Vector2(0, 0)
		uv_b = uv_offset + Vector2(0, uv_height)
		uv_c = uv_offset + Vector2(uv_width, uv_height)
		uv_d = uv_offset + Vector2(uv_width, 0)
		
		aost.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
		aost.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
		has_ao = true
	
	var q1: bool = false
	var q2: bool = false
	var q3: bool = false
	var q4: bool = false
	
	if face == TOP:
		if q1_ao:
			q1 = !check_transparency(x + 1, y + 1, z + 1)
		if q2_ao:
			q2 = !check_transparency(x - 1, y + 1, z + 1)
		if q3_ao:
			q3 = !check_transparency(x - 1, y + 1, z - 1)
		if q4_ao:
			q4 = !check_transparency(x + 1, y + 1, z - 1)
	elif face == BOTTOM:
		if q1_ao:
			q1 = !check_transparency(x + 1, y - 1, z + 1)
		if q4_ao:
			q4 = !check_transparency(x - 1, y - 1, z + 1)
		if q3_ao:
			q3 = !check_transparency(x - 1, y - 1, z - 1)
		if q2_ao:
			q2 = !check_transparency(x + 1, y - 1, z - 1)
	elif face == LEFT:
		if q3_ao:
			q3 = !check_transparency(x - 1, y + 1, z + 1)
		if q4_ao:
			q4 = !check_transparency(x - 1, y - 1, z + 1)
		if q1_ao:
			q1 = !check_transparency(x - 1, y - 1, z - 1)
		if q2_ao:
			q2 = !check_transparency(x - 1, y + 1, z - 1)
	elif face == RIGHT:
		if q2_ao:
			q2 = !check_transparency(x + 1, y + 1, z + 1)
		if q1_ao:
			q1 = !check_transparency(x + 1, y - 1, z + 1)
		if q4_ao:
			q4 = !check_transparency(x + 1, y - 1, z - 1)
		if q3_ao:
			q3 = !check_transparency(x + 1, y + 1, z - 1)
	elif face == FRONT:
		if q3_ao:
			q3 = !check_transparency(x + 1, y + 1, z + 1)
		if q2_ao:
			q2 = !check_transparency(x - 1, y + 1, z + 1)
		if q1_ao:
			q1 = !check_transparency(x - 1, y - 1, z + 1)
		if q4_ao:
			q4 = !check_transparency(x + 1, y - 1, z + 1)
	elif face == BACK:
		if q2_ao:
			q2 = !check_transparency(x + 1, y + 1, z - 1)
		if q3_ao:
			q3 = !check_transparency(x - 1, y + 1, z - 1)
		if q4_ao:
			q4 = !check_transparency(x - 1, y - 1, z - 1)
		if q1_ao:
			q1 = !check_transparency(x + 1, y - 1, z - 1)
	
	uv_offset = createAmbientOnCorner(q1, q2, q3, q4, corner_ao)
	
	if GameData.enable_chunk_update_cache:
		blocks_cache[x][y][z][face]["corner_ao"] = uv_offset
	
	if uv_offset != null:
		
		uv_offset /= GameData.AO_ATLAS_SIZE
		uv_a = uv_offset + Vector2(0, 0)
		uv_b = uv_offset + Vector2(0, uv_height)
		uv_c = uv_offset + Vector2(uv_width, uv_height)
		uv_d = uv_offset + Vector2(uv_width, 0)
		
		caost.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
		caost.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))
		has_cao = true


func createAmbientOnSide(x_min: bool, x_plus: bool, z_min: bool, z_plus: bool):
	
	
	var uv_offset
	var corner_ao: bool = true
	var q1_ao: bool = true
	var q2_ao: bool = true
	var q3_ao: bool = true
	var q4_ao: bool = true
	
	if !z_plus and !z_min and !x_plus and !x_min:
		uv_offset = null
		
	elif z_plus and z_min and x_plus and x_min:
		uv_offset = Vector2(0, 3)
		corner_ao = false
		
	elif z_plus and z_min and x_plus:
		uv_offset = Vector2(3, 2)
		corner_ao = false
	elif z_plus and z_min and x_min:
		uv_offset = Vector2(1, 2)
		corner_ao = false
	elif x_plus and x_min and z_min:
		uv_offset = Vector2(2, 2)
		corner_ao = false
	elif x_plus and x_min and z_plus:
		uv_offset = Vector2(0, 2)
		corner_ao = false
		
	elif x_plus and x_min:
		uv_offset = Vector2(2, 3)
		corner_ao = false
	elif z_plus and z_min:
		uv_offset = Vector2(1, 3)
		corner_ao = false
		
	elif x_plus and z_min:
		uv_offset = Vector2(2, 1)
		q1_ao = false
		q3_ao = false
		q4_ao = false
	elif x_plus and z_plus:
		uv_offset = Vector2(3, 1)
		q4_ao = false
		q1_ao = false
		q2_ao = false
	elif x_min and z_min:
		uv_offset = Vector2(0, 1)
		q2_ao = false
		q3_ao = false
		q4_ao = false
	elif x_min and z_plus:
		uv_offset = Vector2(1, 1)
		q3_ao = false
		q2_ao = false
		q1_ao = false
		
	elif x_plus:
		uv_offset = Vector2(0, 0)
		q1_ao = false
		q4_ao = false
	elif x_min:
		uv_offset = Vector2(2, 0)
		q2_ao = false
		q3_ao = false
	elif z_plus:
		uv_offset = Vector2(3, 0)
		q1_ao = false
		q2_ao = false
	elif z_min:
		uv_offset = Vector2(1, 0)
		q3_ao = false
		q4_ao = false
		
	else:
		uv_offset = null
	
	return {
		"uv_offset": uv_offset,
		"corner_ao": corner_ao,
		"q1_ao":	 q1_ao,
		"q2_ao":	 q2_ao,
		"q3_ao":	 q3_ao,
		"q4_ao":	 q4_ao,
	}


func createAmbientOnCorner(q1: bool, q2: bool, q3: bool, q4: bool, corner_ao: bool):
	
	
	var uv_offset
	
	if (!q1 and !q2 and !q3 and !q4) or not corner_ao:
		uv_offset = null
		
	elif q1 and q2 and q3 and q4:
		uv_offset = Vector2(0, 7)
		
	elif q1 and q2 and q3:
		uv_offset = Vector2(0, 6)
	elif q2 and q3 and q4:
		uv_offset = Vector2(3, 6)
	elif q3 and q4 and q1:
		uv_offset = Vector2(2, 6)
	elif q4 and q1 and q2:
		uv_offset = Vector2(1, 6)
		
	elif q1 and q2:
		uv_offset = Vector2(0, 5)
	elif q2 and q3:
		uv_offset = Vector2(1, 5)
	elif q3 and q4:
		uv_offset = Vector2(2, 5)
	elif q4 and q1:
		uv_offset = Vector2(3, 5)
		
	elif q1 and q3:
		uv_offset = Vector2(2, 7)
	elif q2 and q4:
		uv_offset = Vector2(1, 7)
		
	elif q1:
		uv_offset = Vector2(3, 4)
	elif q2:
		uv_offset = Vector2(2, 4)
	elif q3:
		uv_offset = Vector2(1, 4)
	elif q4:
		uv_offset = Vector2(0, 4)
	
	return uv_offset


func set_chunk_position(new_postion: Vector3):
	
	
	chunk_position = new_postion
	translation = chunk_position * (GameData.CHUNK_DIMENSION * GameData.CHUNK_SCALING)
	self.name = str(chunk_position)


func place_block(position, type):
	
	
	position -= translation
	position.x = round((position.x - 1) / GameData.CHUNK_SCALING)
	position.y = round((position.y - 1) / GameData.CHUNK_SCALING)
	position.z = round((position.z - 1) / GameData.CHUNK_SCALING)
	
	
	if position.x >= GameData.CHUNK_DIMENSION.x:
		position.x = 0
		var neighboring_chunk = str(chunk_position + Vector3(1, 0, 0))
		if get_parent().has_node(neighboring_chunk):
			get_parent().get_node(neighboring_chunk).place_block_from_neighbor(position, type)
			if GameData.enable_seamless_chunk_mesh:
				update()
		return
	if position.z >= GameData.CHUNK_DIMENSION.z:
		position.z = 0
		var neighboring_chunk = str(chunk_position + Vector3(0, 0, 1))
		if get_parent().has_node(neighboring_chunk):
			get_parent().get_node(neighboring_chunk).place_block_from_neighbor(position, type)
			if GameData.enable_seamless_chunk_mesh:
				update()
		return
	if position.y >= GameData.CHUNK_DIMENSION.y:
		position.y = 0
		var neighboring_chunk = str(chunk_position + Vector3(0, 1, 0))
		if get_parent().has_node(neighboring_chunk):
			get_parent().get_node(neighboring_chunk).place_block_from_neighbor(position, type)
			if GameData.enable_seamless_chunk_mesh:
				update()
		return
	
	if position.x < 0:
		position.x = (GameData.CHUNK_DIMENSION.x - 1)
		var neighboring_chunk = str(chunk_position + Vector3(-1, 0, 0))
		if get_parent().has_node(neighboring_chunk):
			get_parent().get_node(neighboring_chunk).place_block_from_neighbor(position, type)
			if GameData.enable_seamless_chunk_mesh:
				update()
		return
	if position.z < 0:
		position.z = (GameData.CHUNK_DIMENSION.x - 1)
		var neighboring_chunk = str(chunk_position + Vector3(0, 0, -1))
		if get_parent().has_node(neighboring_chunk):
			get_parent().get_node(neighboring_chunk).place_block_from_neighbor(position, type)
			if GameData.enable_seamless_chunk_mesh:
				update()
		return
	if position.y < 0:
		position.y = (GameData.CHUNK_DIMENSION.x - 1)
		var neighboring_chunk = str(chunk_position + Vector3(0, -1, 0))
		if get_parent().has_node(neighboring_chunk):
			get_parent().get_node(neighboring_chunk).place_block_from_neighbor(position, type)
			if GameData.enable_seamless_chunk_mesh:
				update()
		return
	
	
	if blocks[position.x][position.y][position.z] != GameData.BLOCKS.AIR:
		return
	
	if GameData.enable_chunk_update_cache:
		for x in [-1, 0, 1]:
			for y in [-1, 0, 1]:
				for z in [-1, 0, 1]:
					remove_block_cache(position.x + x, position.y + y, position.z + z)
	
	blocks[position.x][position.y][position.z] = type
	update()
	
	if GameData.enable_seamless_chunk_mesh:
		
		var neighboring_chunk_position: Vector3 = Vector3()
		
		if position.x == (GameData.CHUNK_DIMENSION.x - 1):
			neighboring_chunk_position.x += 1
			var neighboring_chunk = str(chunk_position + Vector3(1, 0, 0))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		elif position.x == 0:
			neighboring_chunk_position.x -= 1
			var neighboring_chunk = str(chunk_position + Vector3(-1, 0, 0))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		
		if position.y == (GameData.CHUNK_DIMENSION.y - 1):
			neighboring_chunk_position.y += 1
			var neighboring_chunk = str(chunk_position + Vector3(0, 1, 0))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		elif position.y == 0:
			neighboring_chunk_position.y -= 1
			var neighboring_chunk = str(chunk_position + Vector3(0, -1, 0))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		
		if position.z == (GameData.CHUNK_DIMENSION.z - 1):
			neighboring_chunk_position.z += 1
			var neighboring_chunk = str(chunk_position + Vector3(0, 0, 1))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		elif position.z == 0:
			neighboring_chunk_position.z -= 1
			var neighboring_chunk = str(chunk_position + Vector3(0, 0, -1))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		
		if (
			neighboring_chunk_position != Vector3(1, 0, 0) and
			neighboring_chunk_position != Vector3(-1, 0, 0) and
			neighboring_chunk_position != Vector3(0, 1, 0) and
			neighboring_chunk_position != Vector3(0, -1, 0) and
			neighboring_chunk_position != Vector3(0, 0, 1) and
			neighboring_chunk_position != Vector3(0, 0, -1)
		):
			var neighboring_chunk = str(chunk_position + neighboring_chunk_position)
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()


func place_block_from_neighbor(position, type):
	
	
	if blocks[position.x][position.y][position.z] != GameData.BLOCKS.AIR:
		return
	
	if GameData.enable_chunk_update_cache:
		for x in [-1, 0, 1]:
			for y in [-1, 0, 1]:
				for z in [-1, 0, 1]:
					remove_block_cache(position.x + x, position.y + y, position.z + z)
	
	blocks[position.x][position.y][position.z] = type
	update()


func break_block(position):
	
	
	position -= translation
	position.x = round((position.x - 1) / GameData.CHUNK_SCALING)
	position.y = round((position.y - 1) / GameData.CHUNK_SCALING)
	position.z = round((position.z - 1) / GameData.CHUNK_SCALING)
	
	if (
		position.x >= GameData.CHUNK_DIMENSION.x or position.x < 0 or
		position.y >= GameData.CHUNK_DIMENSION.y or position.y < 0 or
		position.z >= GameData.CHUNK_DIMENSION.z or position.z < 0
	):
		return
	
	if blocks[position.x][position.y][position.z] == GameData.BLOCKS.AIR:
		return
	
	if GameData.enable_chunk_update_cache:
		for x in [-1, 0, 1]:
			for y in [-1, 0, 1]:
				for z in [-1, 0, 1]:
					remove_block_cache(position.x + x, position.y + y, position.z + z)
	
	blocks[position.x][position.y][position.z] = GameData.BLOCKS.AIR
	update()
	
	if GameData.enable_seamless_chunk_mesh:
		
		var neighboring_chunk_position: Vector3 = Vector3()
		
		if position.x == (GameData.CHUNK_DIMENSION.x - 1):
			neighboring_chunk_position.x += 1
			var neighboring_chunk = str(chunk_position + Vector3(1, 0, 0))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		elif position.x == 0:
			neighboring_chunk_position.x -= 1
			var neighboring_chunk = str(chunk_position + Vector3(-1, 0, 0))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		
		if position.y == (GameData.CHUNK_DIMENSION.y - 1):
			neighboring_chunk_position.y += 1
			var neighboring_chunk = str(chunk_position + Vector3(0, 1, 0))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		elif position.y == 0:
			neighboring_chunk_position.y -= 1
			var neighboring_chunk = str(chunk_position + Vector3(0, -1, 0))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		
		if position.z == (GameData.CHUNK_DIMENSION.z - 1):
			neighboring_chunk_position.z += 1
			var neighboring_chunk = str(chunk_position + Vector3(0, 0, 1))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		elif position.z == 0:
			neighboring_chunk_position.z -= 1
			var neighboring_chunk = str(chunk_position + Vector3(0, 0, -1))
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()
		
		if (
			neighboring_chunk_position != Vector3(1, 0, 0) and
			neighboring_chunk_position != Vector3(-1, 0, 0) and
			neighboring_chunk_position != Vector3(0, 1, 0) and
			neighboring_chunk_position != Vector3(0, -1, 0) and
			neighboring_chunk_position != Vector3(0, 0, 1) and
			neighboring_chunk_position != Vector3(0, 0, -1)
		):
			var neighboring_chunk = str(chunk_position + neighboring_chunk_position)
			if get_parent().has_node(neighboring_chunk):
				get_parent().get_node(neighboring_chunk).update()


func remove_block_cache(x: int, y: int, z: int):
	
	
	if (
		x >= 0 and x < GameData.CHUNK_DIMENSION.x and
		y >= 0 and y < GameData.CHUNK_DIMENSION.y and
		z >= 0 and z < GameData.CHUNK_DIMENSION.z
	):
		blocks_cache[x][y][z] = null
		return
	
	var position = Vector3(x, y, z)
	var neighboring_chunk_position = chunk_position
	
	if position.x >= GameData.CHUNK_DIMENSION.x:
		position.x = 0
		neighboring_chunk_position.x += 1
	elif position.x < 0:
		position.x = (GameData.CHUNK_DIMENSION.x - 1)
		neighboring_chunk_position.x -= 1
	
	if position.y >= GameData.CHUNK_DIMENSION.y:
		position.y = 0
		neighboring_chunk_position.y += 1
	elif position.y < 0:
		position.y = (GameData.CHUNK_DIMENSION.x - 1)
		neighboring_chunk_position.y -= 1
	
	if position.z >= GameData.CHUNK_DIMENSION.z:
		position.z = 0
		neighboring_chunk_position.z += 1
	elif position.z < 0:
		position.z = (GameData.CHUNK_DIMENSION.x - 1)
		neighboring_chunk_position.z -= 1
	
	var neighboring_chunk = str(neighboring_chunk_position)
	
	if get_parent().has_node(neighboring_chunk):
		get_parent().get_node(neighboring_chunk).blocks_cache[position.x][position.y][position.z] = null

