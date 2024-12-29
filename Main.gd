extends Spatial


onready var Chunks: Spatial = $Chunks
onready var Player: KinematicBody = $KinematicBody


var Chunk = preload("res://Chunk/Chunk.tscn")
var load_radius = 7
var load_height = 7
var update_voxel_ao: bool = false
var update_seamless_chunk: bool = false
var load_thread: Thread = Thread.new()
var mutex: Mutex = Mutex.new()


func _ready():
	
	
	if OS.get_name() == "Android":
		load_radius = 5
		load_height = 5
	
	
	set_physics_process(false)
	$DirectionalLight.shadow_enabled = GameData.enable_realtime_shadow
	$WorldEnvironment.environment.ssao_enabled = GameData.enable_realtime_ao
	GameData.connect("seamless_chunk_mesh_changed", self, "seamless_chunk_mesh_changed")
	GameData.connect("realtime_shadow_changed", self, "realtime_shadow_changed")
	GameData.connect("realtime_ao_changed", self, "realtime_ao_changed")
	GameData.connect("voxel_ao_changed", self, "voxel_ao_changed")
	
	
	for i in range(0, load_radius):
		for j in range(0, load_height):
			for k in range(0, load_radius):
				var chunk = Chunk.instance()
				Chunks.add_child(chunk)
				chunk.set_chunk_position(Vector3(i, j, k))
	
	yield(get_tree().create_timer(1), "timeout")
	
	var index: int = 0
	
	for chunk in Chunks.get_children():
		
		var cx = chunk.chunk_position.x
		var cy = chunk.chunk_position.y
		var cz = chunk.chunk_position.z
		
		var px = floor(Player.translation.x / (GameData.CHUNK_DIMENSION.x * GameData.CHUNK_SCALING))
		var py = floor(Player.translation.y / (GameData.CHUNK_DIMENSION.y * GameData.CHUNK_SCALING))
		var pz = floor(Player.translation.z / (GameData.CHUNK_DIMENSION.z * GameData.CHUNK_SCALING))
		
		var new_x = posmod(cx - px + load_radius / 2, load_radius) + px - load_radius / 2
		var new_y = posmod(cy - py + load_height / 2, load_height) + py - load_height / 2
		var new_z = posmod(cz - pz + load_radius / 2, load_radius) + pz - load_radius / 2
		
		if (new_x != cx or new_z != cz or new_y != cy):
			chunk.set_chunk_position(Vector3(int(new_x), int(new_y), int(new_z)))
			chunk.generate()
			chunk.update()
		elif !chunk.generated:
			chunk.generate()
			chunk.update()
		
		yield(get_tree().create_timer(0.01), "timeout")
		index += 1
	
	load_thread.start(self, "_thread_process", null)
	
	# this mesh instance store the water shader
	# the purpose of this code is to force the engine to compile water shader too (so there will be no lag spike)
	# and then we hide meshinstance
	$MeshInstance.hide()


func _thread_process(_userdata):
	
	
	while(true):
		
		update_chunks()
		
		if update_voxel_ao or update_seamless_chunk:
			
			for chunk in Chunks.get_children():
				chunk.reset_cache()
				chunk.update()
			
			mutex.lock()
			if Player.has_method("set_unfreeze"):
				Player.set_unfreeze()
			
			update_voxel_ao = false
			update_seamless_chunk = false
			mutex.unlock()


func update_chunks():
	
	
	for chunk in Chunks.get_children():
		
		var cx = chunk.chunk_position.x
		var cy = chunk.chunk_position.y
		var cz = chunk.chunk_position.z
		
		var px = floor(Player.translation.x / (GameData.CHUNK_DIMENSION.x * GameData.CHUNK_SCALING))
		var py = floor(Player.translation.y / (GameData.CHUNK_DIMENSION.y * GameData.CHUNK_SCALING))
		var pz = floor(Player.translation.z / (GameData.CHUNK_DIMENSION.z * GameData.CHUNK_SCALING))
		
		var new_x = posmod(cx - px + load_radius / 2, load_radius) + px - load_radius / 2
		var new_y = posmod(cy - py + load_height / 2, load_height) + py - load_height / 2
		var new_z = posmod(cz - pz + load_radius / 2, load_radius) + pz - load_radius / 2
		
		if (new_x != cx or new_z != cz or new_y != cy):
			chunk.set_chunk_position(Vector3(int(new_x), int(new_y), int(new_z)))
			chunk.generate()
			chunk.update()
		elif !chunk.generated:
			chunk.generate()
			chunk.update()


func realtime_shadow_changed():
	
	$DirectionalLight.shadow_enabled = GameData.enable_realtime_shadow


func realtime_ao_changed():
	
	$WorldEnvironment.environment.ssao_enabled = GameData.enable_realtime_ao


func voxel_ao_changed():
	
	
	mutex.lock()
	GameData.updated_chunk = 0
	
	if Player.has_method("set_freeze"):
		Player.set_freeze()
	
	yield(get_tree().create_timer(0.2), "timeout")
	
	update_voxel_ao = true
	mutex.unlock()


func seamless_chunk_mesh_changed():
	
	
	mutex.lock()
	GameData.updated_chunk = 0
	
	if Player.has_method("set_freeze"):
		Player.set_freeze()
	
	yield(get_tree().create_timer(0.2), "timeout")
	
	update_seamless_chunk = true
	mutex.unlock()

