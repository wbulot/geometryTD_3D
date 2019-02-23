extends Camera

var targetDirVel = Vector3()
export var speed = 20
export var sensibility = 0.2
export var PhoneSensibility = 0.2

func _ready():
	pass

func _process(delta):
	calcCamDir(delta)
	if(Input.is_action_pressed("sprint")):
		$"..".global_transform.origin += targetDirVel.normalized()*delta*speed*2
	else:
		$"..".global_transform.origin += targetDirVel.normalized()*delta*speed
	targetDirVel = Vector3()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			$"..".global_transform.origin -= $"..".global_transform.basis.z*sensibility
		if event.button_index == BUTTON_WHEEL_DOWN:
			$"..".global_transform.origin += $"..".global_transform.basis.z*sensibility
			
#	if event is InputEventMouseMotion:
#		if Input.is_mouse_button_pressed(BUTTON_RIGHT):
#			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#			$"..".rotation_degrees.x -= event.relative.y*sensibility
#			if $"..".rotation_degrees.x < -67.5:
#				$"..".rotation_degrees.x = -67.5
#			if $"..".rotation_degrees.x > 0:
#				$"..".rotation_degrees.x = 0
#			$"..".rotation_degrees.y -= event.relative.x*sensibility
#		else:
#			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
	if event is InputEventScreenDrag:
#		$"..".rotation_degrees.y += event.relative.x*sensibility
		$"..".global_transform.origin.x -= event.relative.x*sensibility
		
#		$"..".rotation_degrees.x += event.relative.y*sensibility
		$"..".global_transform.origin.z -= event.relative.y*sensibility


func calcCamDir(delta):
	if(Input.is_action_pressed("moveFw")):
		var basisZ = $"..".global_transform.basis.z
		basisZ.y = 0
		targetDirVel -= basisZ
	if(Input.is_action_pressed("moveBw")):
		var basisZ = $"..".global_transform.basis.z
		basisZ.y = 0
		targetDirVel += basisZ
	if(Input.is_action_pressed("moveLeft")):
		targetDirVel -= $"..".global_transform.basis.x
	if(Input.is_action_pressed("moveRight")):
		targetDirVel += $"..".global_transform.basis.x
	if(Input.is_action_pressed("moveUp")):
		targetDirVel -= $"..".global_transform.basis.z
	if(Input.is_action_pressed("moveDown")):
		targetDirVel += $"..".global_transform.basis.z