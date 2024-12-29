extends Panel


var button = preload("res://Player/InventoryButton.tscn")


func _ready():
	
	hide()
	
	var index = 0
	for block in GameData.BLOCKS:
		if block == "AIR":
			index += 1
			continue
		
		var inv_button = button.instance()
		$ScrollContainer/GridContainer.add_child(inv_button)
		inv_button.text = block
		inv_button.connect("pressed", get_parent().get_parent(), "set_place_type", [index])
		index += 1
	
	$Close.connect("pressed", get_parent().get_parent(), "close_inventory")
