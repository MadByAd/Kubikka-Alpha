extends Node


enum PROPERTY {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	SOLID,
	LIQUID,
	TRANSPARENT,
}
enum BLOCKS {
	AIR,
	DIRT,
	GRASS,
	STONE,
	COBBLE,
	SAND,
	LEAVES,
	GLASS,
	WOOD,
	LOG,
	BRICK,
	WATER,
	TOXIC_WATER,
	LAVA,
	MILK,
}


const CHUNK_DIMENSION: Vector3 = Vector3(16, 16, 16)
const CHUNK_SCALING: int = 2
const BLOCK_ATLAS_SIZE: Vector2 = Vector2(4, 4)
const AO_ATLAS_SIZE: Vector2 = Vector2(4, 8)
const TYPES: Dictionary = {
	BLOCKS.AIR: {
		PROPERTY.SOLID: false,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.DIRT: {
		PROPERTY.TOP	: Vector2(1, 0),
		PROPERTY.BOTTOM	: Vector2(1, 0),
		PROPERTY.LEFT	: Vector2(1, 0),
		PROPERTY.RIGHT	: Vector2(1, 0),
		PROPERTY.FRONT	: Vector2(1, 0),
		PROPERTY.BACK	: Vector2(1, 0),
		PROPERTY.SOLID	: true,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.GRASS: {
		PROPERTY.TOP	: Vector2(2, 0),
		PROPERTY.BOTTOM	: Vector2(1, 0),
		PROPERTY.LEFT	: Vector2(0, 0),
		PROPERTY.RIGHT	: Vector2(0, 0),
		PROPERTY.FRONT	: Vector2(0, 0),
		PROPERTY.BACK	: Vector2(0, 0),
		PROPERTY.SOLID	: true,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.STONE: {
		PROPERTY.TOP	: Vector2(3, 0),
		PROPERTY.BOTTOM	: Vector2(3, 0),
		PROPERTY.LEFT	: Vector2(3, 0),
		PROPERTY.RIGHT	: Vector2(3, 0),
		PROPERTY.FRONT	: Vector2(3, 0),
		PROPERTY.BACK	: Vector2(3, 0),
		PROPERTY.SOLID	: true,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.COBBLE: {
		PROPERTY.TOP	: Vector2(0, 1),
		PROPERTY.BOTTOM	: Vector2(0, 1),
		PROPERTY.LEFT	: Vector2(0, 1),
		PROPERTY.RIGHT	: Vector2(0, 1),
		PROPERTY.FRONT	: Vector2(0, 1),
		PROPERTY.BACK	: Vector2(0, 1),
		PROPERTY.SOLID	: true,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.SAND: {
		PROPERTY.TOP	: Vector2(1, 1),
		PROPERTY.BOTTOM	: Vector2(1, 1),
		PROPERTY.LEFT	: Vector2(1, 1),
		PROPERTY.RIGHT	: Vector2(1, 1),
		PROPERTY.FRONT	: Vector2(1, 1),
		PROPERTY.BACK	: Vector2(1, 1),
		PROPERTY.SOLID	: true,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.LEAVES: {
		PROPERTY.TOP	: Vector2(2, 1),
		PROPERTY.BOTTOM	: Vector2(2, 1),
		PROPERTY.LEFT	: Vector2(2, 1),
		PROPERTY.RIGHT	: Vector2(2, 1),
		PROPERTY.FRONT	: Vector2(2, 1),
		PROPERTY.BACK	: Vector2(2, 1),
		PROPERTY.SOLID	: false,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: true,
	},
	BLOCKS.GLASS: {
		PROPERTY.TOP	: Vector2(3, 1),
		PROPERTY.BOTTOM	: Vector2(3, 1),
		PROPERTY.LEFT	: Vector2(3, 1),
		PROPERTY.RIGHT	: Vector2(3, 1),
		PROPERTY.FRONT	: Vector2(3, 1),
		PROPERTY.BACK	: Vector2(3, 1),
		PROPERTY.SOLID	: false,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: true,
	},
	BLOCKS.WOOD: {
		PROPERTY.TOP	: Vector2(0, 2),
		PROPERTY.BOTTOM	: Vector2(0, 2),
		PROPERTY.LEFT	: Vector2(0, 2),
		PROPERTY.RIGHT	: Vector2(0, 2),
		PROPERTY.FRONT	: Vector2(0, 2),
		PROPERTY.BACK	: Vector2(0, 2),
		PROPERTY.SOLID	: true,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.LOG: {
		PROPERTY.TOP	: Vector2(1, 2),
		PROPERTY.BOTTOM	: Vector2(1, 2),
		PROPERTY.LEFT	: Vector2(2, 2),
		PROPERTY.RIGHT	: Vector2(2, 2),
		PROPERTY.FRONT	: Vector2(2, 2),
		PROPERTY.BACK	: Vector2(2, 2),
		PROPERTY.SOLID	: true,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.BRICK: {
		PROPERTY.TOP	: Vector2(3, 2),
		PROPERTY.BOTTOM	: Vector2(3, 2),
		PROPERTY.LEFT	: Vector2(3, 2),
		PROPERTY.RIGHT	: Vector2(3, 2),
		PROPERTY.FRONT	: Vector2(3, 2),
		PROPERTY.BACK	: Vector2(3, 2),
		PROPERTY.SOLID	: true,
		PROPERTY.LIQUID	: false,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.WATER: {
		PROPERTY.TOP	: Vector2(0, 3),
		PROPERTY.BOTTOM	: Vector2(0, 3),
		PROPERTY.LEFT	: Vector2(0, 3),
		PROPERTY.RIGHT	: Vector2(0, 3),
		PROPERTY.FRONT	: Vector2(0, 3),
		PROPERTY.BACK	: Vector2(0, 3),
		PROPERTY.SOLID	: false,
		PROPERTY.LIQUID	: true,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.TOXIC_WATER: {
		PROPERTY.TOP	: Vector2(1, 3),
		PROPERTY.BOTTOM	: Vector2(1, 3),
		PROPERTY.LEFT	: Vector2(1, 3),
		PROPERTY.RIGHT	: Vector2(1, 3),
		PROPERTY.FRONT	: Vector2(1, 3),
		PROPERTY.BACK	: Vector2(1, 3),
		PROPERTY.SOLID	: false,
		PROPERTY.LIQUID	: true,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.LAVA: {
		PROPERTY.TOP	: Vector2(2, 3),
		PROPERTY.BOTTOM	: Vector2(2, 3),
		PROPERTY.LEFT	: Vector2(2, 3),
		PROPERTY.RIGHT	: Vector2(2, 3),
		PROPERTY.FRONT	: Vector2(2, 3),
		PROPERTY.BACK	: Vector2(2, 3),
		PROPERTY.SOLID	: false,
		PROPERTY.LIQUID	: true,
		PROPERTY.TRANSPARENT: false,
	},
	BLOCKS.MILK: {
		PROPERTY.TOP	: Vector2(3, 3),
		PROPERTY.BOTTOM	: Vector2(3, 3),
		PROPERTY.LEFT	: Vector2(3, 3),
		PROPERTY.RIGHT	: Vector2(3, 3),
		PROPERTY.FRONT	: Vector2(3, 3),
		PROPERTY.BACK	: Vector2(3, 3),
		PROPERTY.SOLID	: false,
		PROPERTY.LIQUID	: true,
		PROPERTY.TRANSPARENT: false,
	},
}


var updated_chunk: int = 0
var spawned_chunk: int = 0

var enable_seamless_chunk_mesh: bool = true setget set_seamless_chunk_mesh
var enable_chunk_update_cache: bool = true setget set_chunk_update_cache
var enable_realtime_shadow: bool = false setget set_realtime_shadow
var enable_realtime_ao: bool = false setget set_realtime_ao
var enable_voxel_ao: bool = true setget set_voxel_ao


signal seamless_chunk_mesh_changed
signal chunk_update_cache_changed
signal realtime_shadow_changed
signal realtime_ao_changed
signal voxel_ao_changed


func set_seamless_chunk_mesh(new_value):
	
	enable_seamless_chunk_mesh = new_value
	emit_signal("seamless_chunk_mesh_changed")


func set_chunk_update_cache(new_value):
	
	enable_chunk_update_cache = new_value
	emit_signal("chunk_update_cache_changed")


func set_realtime_shadow(new_value):
	
	enable_realtime_shadow = new_value
	emit_signal("realtime_shadow_changed")


func set_realtime_ao(new_value):
	
	enable_realtime_ao = new_value
	emit_signal("realtime_ao_changed")


func set_voxel_ao(new_value):
	
	enable_voxel_ao = new_value
	emit_signal("voxel_ao_changed")

