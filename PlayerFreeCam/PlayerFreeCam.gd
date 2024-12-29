extends KinematicBody


const MAX_LOOK_ANGLE: float = deg2rad(90)


var speed: int = 20
var sensitivity: float = 0.15
var direction: Vector3 = Vector3()


func _ready():
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * sensitivity))
		$Head.rotate_x(deg2rad(-event.relative.y * sensitivity))
		$Head.rotation.x = clamp($Head.rotation.x, -MAX_LOOK_ANGLE, MAX_LOOK_ANGLE)


func _physics_process(delta):
	
	direction = Vector3()
	
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	if Input.is_action_pressed("move_down"):
		direction -= transform.basis.y
	elif Input.is_action_pressed("move_up"):
		direction += transform.basis.y
	
	direction = direction.normalized()
	move_and_slide(direction * speed, Vector3.UP)

