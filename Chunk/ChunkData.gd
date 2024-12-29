extends Node


var stored_data: Dictionary = {}


func load_chunk(position: Vector3):
	
	var key = str(Vector3(position.x, position.y, position.z))
	
	if stored_data.has(key):
		return stored_data[key]
	return null


func store_chunk(position: Vector3, data: Array):
	
	var key = str(Vector3(position.x, position.y, position.z))
	
	stored_data[key] = data

