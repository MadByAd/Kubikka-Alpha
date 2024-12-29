extends MeshInstance


var collided: Array = []


func _ready():
	
	$Area.connect("body_entered", self, "body_entered")
	$Area.connect("body_exited", self, "body_exited")


func body_entered(body):
	
	if body.is_in_group("player"):
		collided.append(body)


func body_exited(body):
	
	if body.is_in_group("player"):
		collided.erase(body)

