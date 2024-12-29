extends KinematicBody


const CAMERA_MAX_ANGLE: float = deg2rad(90)


onready var Head: Spatial = $Head
onready var GroundCheck: RayCast = $GroundCheck
onready var DebugLabel: Label = $DebugUI/Panel/Label
onready var Raycast: RayCast = $Head/RayCast
onready var CastPointer: MeshInstance = $CastPointer
onready var TargetChunk: Spatial = null


var camera_sensitivity: float = 0.15
var walking_speed: float = 6 # 6
var running_speed: float = 8
var speed: float = walking_speed
var fall: float = 40
var jump: float = 13.5
var gravity: Vector3 = Vector3()
var movement: Vector3 = Vector3()
var direction: Vector3 = Vector3()
var chunk_position: Vector3 = Vector3()
var place_type: int = GameData.BLOCKS.COBBLE
var freeze: bool = true
var freeze_loading: bool = false


func _ready():
	
	
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$CanvasLayer.show()
	$DebugUI/Inventory/UpdateSensitivity/Button.connect("pressed", self, "update_sensitivity")
	$DebugUI/Inventory/EnableVAO.connect("pressed", self, "enable_voxel_ao")
	$DebugUI/Inventory/EnableRAO.connect("pressed", self, "enable_realtime_ao")
	$DebugUI/Inventory/EnableRShadow.connect("pressed", self, "enable_realtime_shadow")
	$DebugUI/Inventory/EnableSeamlessChunk.connect("pressed", self, "enable_seamless_chunk")
	$DebugUI/Loading.modulate.a = 0.0
	$DebugUI/PleaseWait.visible = false
	
#	$CanvasLayer.hide()


func _input(event):
	
	
	if Input.is_action_just_pressed("inventory"):
		open_inventory()
	
	if (
		(event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED) or
		(event is InputEventScreenDrag)
	):
		rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
		Head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
		Head.rotation.x = clamp(Head.rotation.x, -CAMERA_MAX_ANGLE, CAMERA_MAX_ANGLE)


func _physics_process(delta):
	
	
	handle_debug_screen()
	handle_initial_screen()
	handle_chunk_checks()
	
	if freeze:
		return
	
	handle_raycast()
	physics_process_gravity(delta)
	physics_process_movement()


func physics_process_gravity(delta):
	
	
	if not is_on_floor():
		gravity += Vector3.DOWN * fall * delta
	elif is_on_floor() and GroundCheck.is_colliding():
		gravity = -get_floor_normal() * fall
	else:
		gravity = -get_floor_normal()
	
	if Input.is_action_pressed("jump") and (is_on_floor() or GroundCheck.is_colliding()):
		gravity = Vector3.UP * jump


func physics_process_movement():
	
	direction = Vector3()
	
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	
	if freeze_loading:
		direction = Vector3()
		gravity = Vector3()
	
	direction = direction.normalized() * speed
	movement.x = direction.x + gravity.x
	movement.z = direction.z + gravity.z
	movement.y = gravity.y
	
	move_and_slide(movement, Vector3.UP)


func handle_initial_screen():
	
	if not $CanvasLayer.visible:
		return
	
	if GameData.updated_chunk >= GameData.spawned_chunk:
		freeze = false
		$CanvasLayer/Label.text = "LOADING COMPLETE"
		$CanvasLayer/ColorRect.modulate.a = lerp($CanvasLayer/ColorRect.modulate.a, 0, 0.05)
		yield(get_tree().create_timer(2), "timeout")
		$CanvasLayer.hide()
	else:
		$CanvasLayer/Label.text = "LOADING INITIAL CHUNK\n%d / %d" % [GameData.updated_chunk, GameData.spawned_chunk]


func handle_chunk_checks():
	
	
	chunk_position.x = floor(self.translation.x / (GameData.CHUNK_DIMENSION.x * GameData.CHUNK_SCALING))
	chunk_position.y = floor(self.translation.y / (GameData.CHUNK_DIMENSION.y * GameData.CHUNK_SCALING))
	chunk_position.z = floor(self.translation.z / (GameData.CHUNK_DIMENSION.z * GameData.CHUNK_SCALING))
	
	
	if not get_parent().Chunks.has_node(str(chunk_position)):
		freeze_loading = true
		$DebugUI/PleaseWait.visible = true
	else:
		freeze_loading = false
		$DebugUI/PleaseWait.visible = false


func handle_raycast():
	
	
	if Raycast.is_colliding():
		
		var normal = Raycast.get_collision_normal()
		var position = Raycast.get_collision_point() - (normal * 0.5)
		var bx = position_to_bunit(position.x)
		var by = position_to_bunit(position.y - 0.2)
		var bz = position_to_bunit(position.z)
		var bposition = Vector3(bx, by, bz)
		
		CastPointer.global_translation = position
		CastPointer.visible = true
		PlacementOutline.global_translation = bposition + (normal * 2)
		PlacementOutline.visible = true
		BlockOutline.global_translation = bposition
		BlockOutline.global_rotation.y = 0
		BlockOutline.visible = true
		
		TargetChunk = Raycast.get_collider().get_parent().get_parent()
		
		if $DebugUI/Inventory.visible == false:
			if Input.is_action_just_pressed("mouse_left"):
#				TargetChunk.break_block(bposition)
				TargetChunk.call_deferred("break_block", bposition)
			if Input.is_action_just_pressed("mouse_right") and PlacementOutline.collided.empty():
#				TargetChunk.place_block(bposition + (normal * 2), place_type)
				TargetChunk.call_deferred("place_block", bposition + (normal * 2), place_type)
		
	else:
		CastPointer.visible = false
		PlacementOutline.visible = false
		BlockOutline.visible = false
	
	CastPointer.visible = false
#	PlacementOutline.visible = false
#	BlockOutline.visible = false


func position_to_bunit(position: float):
	
	
	var is_negative = 1
	if position < 0:
		position = -position
		is_negative = -1
		if position < 1:
			return 1 * is_negative
	
	position = floor(position)
	position -= (int(position) % 2) - 1
	
	return position * is_negative


func handle_debug_screen():
	
	
	var selected_block = "null"
	for blocks in GameData.BLOCKS:
		if GameData.BLOCKS[blocks] == place_type:
			selected_block = blocks
	
	
	DebugLabel.text = """-------------------------- DEBUG --------------------------
	FPS----------------> %d
	DYNAMIC_MEMORY-----> %s
	STATIC_MEMORY------> %s
	STATIC_PEAK_MEMORY-> %s
	SPAWNED_CHUNK------> %d
	UPDATED_CHUNK------> %d
	PLAYER_POSITION----> %s
	CHUNK_POSITION-----> %s
	BLOCK_POSITION-----> %s
	PLACEMENT_POSITION-> %s
	RAYCAST_POINT------> %s
	RAYCAST_NORMALS----> %s
	TARGET_BLOCK_CHUNK-> %s
	SELECTED_BLOCK-----> %s
	""" % [
		Engine.get_frames_per_second(),
		str(int(OS.get_dynamic_memory_usage() * 0.000001)) + " MB",
		str(int(OS.get_static_memory_peak_usage() * 0.000001)) + " MB",
		str(int(OS.get_static_memory_usage() * 0.000001)) + " MB",
		GameData.spawned_chunk,
		GameData.updated_chunk,
		str(global_transform.origin),
		str(chunk_position),
		str(BlockOutline.global_transform.origin),
		str(PlacementOutline.global_transform.origin),
		str(Raycast.get_collision_point()),
		str(Raycast.get_collision_normal()),
		TargetChunk,
		selected_block,
	]
	
	$DebugUI/Compass.rect_rotation = rad2deg(self.rotation.y)
	$DebugUI/Loading/Label.text = "UPDATING CHUNK\n%d / %d" % [GameData.updated_chunk, GameData.spawned_chunk]
	
	if GameData.enable_realtime_shadow:
		$DebugUI/Inventory/EnableRShadow.text = "DISABLE REALTIME SHADOW"
	else:
		$DebugUI/Inventory/EnableRShadow.text = "ENABLE REALTIME SHADOW"
	
	if GameData.enable_voxel_ao:
		$DebugUI/Inventory/EnableVAO.text = "DISABLE VOXEL AO"
	else:
		$DebugUI/Inventory/EnableVAO.text = "ENABLE VOXEL AO"
	
	if GameData.enable_realtime_ao:
		$DebugUI/Inventory/EnableRAO.text = "DISABLE REALTIME AO"
	else:
		$DebugUI/Inventory/EnableRAO.text = "ENABLE REALTIME AO"
	
	if GameData.enable_seamless_chunk_mesh:
		$DebugUI/Inventory/EnableSeamlessChunk.text = "DISABLE SEAMLESS CHUNK"
	else:
		$DebugUI/Inventory/EnableSeamlessChunk.text = "ENABLE SEAMLESS CHUNK"


func open_inventory():
	
	
	freeze = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$DebugUI/Inventory.show()


func close_inventory():
	
	
	freeze = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	$DebugUI/Inventory.hide()


func set_place_type(type: int):
	
	place_type = type


func update_sensitivity():
	
	camera_sensitivity = $DebugUI/LineEdit.value * 0.01


func enable_voxel_ao():
	
	GameData.enable_voxel_ao = !GameData.enable_voxel_ao


func enable_realtime_ao():
	
	GameData.enable_realtime_ao = !GameData.enable_realtime_ao


func enable_realtime_shadow():
	
	GameData.enable_realtime_shadow = !GameData.enable_realtime_shadow


func enable_seamless_chunk():
	
	GameData.enable_seamless_chunk_mesh = !GameData.enable_seamless_chunk_mesh


func set_freeze():
	
	
	freeze = true
	$DebugUI/Loading.mouse_filter = Control.MOUSE_FILTER_STOP
	$DebugUI/LoadingTween.interpolate_property($DebugUI/Loading, "modulate:a", $DebugUI/Loading.modulate.a, 1.0, 0.2)
	$DebugUI/LoadingTween.start()


func set_unfreeze():
	
	
	$DebugUI/LoadingTween.interpolate_property($DebugUI/Loading, "modulate:a", $DebugUI/Loading.modulate.a, 0.0, 0.2)
	$DebugUI/LoadingTween.start()
	yield(get_tree().create_timer(0.2), "timeout")
	$DebugUI/Loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	freeze = false

