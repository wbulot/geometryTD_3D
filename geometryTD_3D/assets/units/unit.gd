extends KinematicBody

var id = 0

onready var character = get_node(".")

var gravity = -9.8
var velocity = Vector3()
#We need to init dir and targetdir because character will rotate as soon as it is live, following dir direction
#So these variable can't be null or 0. We init them as same value than init facing direction
onready var targetDir = (transform.origin + transform.basis.z.normalized()) - transform.origin
onready var dir = (transform.origin + transform.basis.z.normalized()) - transform.origin

var walkSpeed = 1.65
var runSpeed = walkSpeed*2
var maxSpeed = 0
var speed = 0
var currentSpeed = 0
#var distToGround = 0

onready var nav = get_node("../level/navigation")
var path = []
var pathI = 0
var isMovingToPath = 0

var isLocal = false
var isInit = 0
var isGodMode = 0
var isAlive = 0
var isAttacking = 0

var life = 100
var team = 0

var target
var targetPos = Vector3()

var moveTimer = 0
var shootTimer = 0
var blockedTime = 0
var checkEnemyTime = 0
var deadTimer

func _ready():
	#Can rotate with
#	character.rotation.y = PI #Radian
#	character.rotation_degrees.y = 90 #Degrees
#	transform.basis.z.z = character.rotation.y #Dot ?
	pass

func _process(delta):
	pass

func _physics_process(delta):
	#IsAlive
	if life > 0:
		isAlive = 1
	else:
		isAlive = 0
	
	if isInit && isLocal:
		sendPosToServer()
		if isAlive:
#			calcDistToGround()
			calcTargetDir()
			calcSpeed()
			
			if isMovingToPath:
				if pathI < path.size():
					var distToPath = path[pathI] - character.get_global_transform().origin
					if distToPath.length() < 1:
						pathI += 1
				else:
					isMovingToPath = 0
			
#			for pos in range(path.size()):
#				if pos+1 < path.size():
#					if pos >= pathI:
#						drawLine3D.DrawLine(path[pos], path[pos+1], Color(0, 0, 1), 0.01)
			
			calcRotation()
			
			processSmoothRotate(delta)
		
			processSmoothAccel(delta)
			
			processMove(delta)
		
			#find path behavior
			if moveTimer <= 0:
				if team == 1:
					getPath($"../level/teamArea/team2".transform.origin)
				if team == 2:
					getPath($"../level/teamArea/team1".transform.origin)
				randomize()
				moveTimer = rand_range(9999, 9999)
			else:
				moveTimer -= delta
			
			#Attack behavior
			if isAlive && isAttacking && targetPos != null:
				if shootTimer <= 0:
					shoot(targetPos)
					shootTimer = 1
				else:
					shootTimer -= delta
			
			#check enemy
			if checkEnemyTime <= 0:
				checkEnemies()
				checkEnemyTime = 1
			else:
				checkEnemyTime -= delta
			
func sendPosToServer():
	$"..".clientRelay_updateObjectPosition("unit",id,transform)

func getPath(targetPos):
	path = nav.get_simple_path(character.transform.origin,targetPos)
#	path = $"../level/navigation/gridMap".getPath(character.transform.origin, targetPos)

#	for pos in range(path.size()):
#		if pos+1 < path.size():
#			drawLine3D.DrawLine(path[pos], path[pos+1], Color(0, 0, 1), 3)
			
	#According to our get path algo, the point 0 can be our own cell
	pathI = 0
	
	if path.size() > 0:
		isMovingToPath = 1
		maxSpeed = runSpeed
	else:
		isMovingToPath = 0
		print("nopath")

func calcTargetDir():
	if isMovingToPath:
		if pathI < path.size():
			targetDir = (path[pathI] - character.transform.origin).normalized()
				
	targetDir = targetDir.normalized()

func calcRotation():
	#We set the rotation acording to the face direction
	var angle = atan2(dir.x, dir.z)
	var playerRot = character.get_rotation();
	playerRot.y = angle
	character.set_rotation(playerRot);

func processSmoothRotate(delta):
	var currentAngle = rad2deg(Vector2(dir.x,dir.z).angle())
	var targetAngle = rad2deg(Vector2(targetDir.x,targetDir.z).angle())
	var diff = targetAngle-currentAngle
	#We add 90 because godot is doing wierd things with angle
	diff += 90
	if diff > 88 && diff < 92:
		dir = targetDir
	elif diff > -90 && diff < 90:
		var newDir = GLOBAL.addOrRemoveAngleToDir(false,Vector2(dir.x,dir.z),10*delta)
		dir.x = newDir.y
		dir.z = newDir.x
	else:
		var newDir = GLOBAL.addOrRemoveAngleToDir(true,Vector2(dir.x,dir.z),10*delta)
		dir.x = newDir.y
		dir.z = newDir.x

#	dir.x += sign(targetDir.x-dir.x) * delta
#	dir.z += sign(targetDir.z-dir.z) * delta
	
	#Debug disable smooth
	dir = targetDir
		
	dir.y = 0
	dir = dir.normalized()
	
func calcSpeed():
	if isMovingToPath && !isAttacking:
		if pathI < path.size():
			maxSpeed = runSpeed
		else:
			maxSpeed = 0
	else:
		maxSpeed = 0
		
	if currentSpeed < 0.05:
		speed = 0

func processSmoothAccel(delta):
	if(speed < maxSpeed):
		speed += maxSpeed*2 * delta
	elif(maxSpeed == 0 && speed != 0):
		speed -= 5 * delta
	elif(speed > maxSpeed):
		speed -= maxSpeed*2 * delta
	else:
		speed = maxSpeed
		
#func calcDistToGround():
#	var rayCastResult = get_world().direct_space_state.intersect_ray(character.get_global_transform().origin,character.get_global_transform().origin - Vector3(0,100,0))
#	if(rayCastResult):
#		distToGround = rayCastResult.position - character.get_global_transform().origin
#		distToGround = distToGround.length()
#	else:
#		distToGround = 1000
	
func processMove(delta):
#	print("dirx "+str(dir.x))
#	print("dirz "+str(dir.z))
	#We set the velocity with the direction * the speed
	
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	
	if is_on_floor():
		velocity.y = gravity
	else:
		velocity.y += delta * gravity
#	if distToGround > 0.1: #Try raycast and isonfloor
#		velocity.y += delta * gravity
#	else:
#		velocity.y = 0
	#We move our character
	var currentSpeedVector = move_and_slide(velocity, Vector3(0,1,0),true)
	currentSpeed = currentSpeedVector.length()
	if isMovingToPath && !isAttacking && currentSpeed < 0.1:
		blockedTime += delta
		if blockedTime > 0.5:
			print("we are blocked")
			if team == 1:
				getPath($"../level/teamArea/team2".transform.origin)
			if team == 2:
				getPath($"../level/teamArea/team1".transform.origin)
			blockedTime = 0
	else:
		blockedTime = 0

func checkEnemies():
	target = null
	var direction = character.get_transform().basis.z.normalized()
	
	var allUnits = get_tree().get_nodes_in_group("unit")
	for unit in allUnits:
		if unit.isAlive && unit != character && unit.team != character.team && unit.team != 0:
			var playerToEnemy = unit.transform.origin - character.transform.origin
			if playerToEnemy.length() < 10:
				var enemyDirection = unit.get_transform().basis.z.normalized()
				var dot_product = direction.dot(playerToEnemy.normalized())
				if rad2deg(direction.angle_to(playerToEnemy.normalized())) < 90:
					#Check raycast view
					var lineOfSightDir = (unit.transform.origin - character.transform.origin).normalized()
					var rayCastResult = get_world().direct_space_state.intersect_ray(character.transform.origin + Vector3(0,1,0),unit.transform.origin + Vector3(0,1,0),[self,unit])
					if(rayCastResult):
#						print(rayCastResult)
						pass
					else:
						target = unit
	if target != null:
		targetPos = target.transform.origin + Vector3(0,1,0)
		isAttacking = 1
	else:
		targetPos = Vector3()
		isAttacking = 0
	

func shoot(targetPos):
	var bulletPos = get_global_transform().origin + Vector3(0,1,0)
	var bulletDir = targetPos - bulletPos
	bulletDir = bulletDir.normalized()
	
	var objectId = GLOBAL.randomId()
	var bullet = preload("res://assets/bullets/bullet.tscn").instance()
	bullet.id = objectId
	bullet.set_name("bullet"+str(bullet.id))
	bullet.transform.origin = bulletPos
	#Rotation
	var angle = atan2(bulletDir.x, bulletDir.z)
	var rot = bullet.get_rotation();
	rot.y = angle
	bullet.set_rotation(rot);
	get_parent().add_child(bullet)
	bullet.apply_impulse(Vector3(0,0,0),bulletDir*2)
	rpc_id(1,"registerBullet",get_tree().get_network_unique_id(),bullet.id)

#func hit(baseDamage, bodyPart):
#	if isGodMode == 0:
#		if bodyPart == "head":
#			life -= baseDamage * 3
#		else:
#			life -= baseDamage * 1
#		if life <= 0:
#			die()

func die():
	if isAlive: #Unit will be considered dead at the next frame
		var material = SpatialMaterial.new()
		material.albedo_color = Color(0,0,0)
		$MeshInstance.set_material_override(material)
		
#		deadTimer = 0
#		$CollisionShape.queue_free()
		$Particles.emitting = true
#		$"Skeleton/PhysicalBone_Head".apply_impulse(Vector3(),Vector3(0,1,0));
#		queue_free()

#func checkDeadTime(delta):
#	if deadTimer != null:
#		deadTimer += delta
#		if deadTimer > 5:
##			$Skeleton.physical_bones_stop_simulation()
##			propagate_call("queue_free", [])
#			print("We remove the unit")
#			queue_free()

func initUnit():
	chooseTeamColor()
	isInit = 1

func chooseTeamColor():
	if team == 1:
		var material = preload("res://materials/team/materialTeam1.tres")
		$MeshInstance.set_material_override(material)
	if team == 2:
		var material = preload("res://materials/team/materialTeam2.tres")
		$MeshInstance.set_material_override(material)
	if team == 3:
		var material = SpatialMaterial.new()
		material.albedo_color = Color(0,0,255)
		$MeshInstance.set_material_override(material)

remote func updateLife(sLife):
	life = sLife
	if sLife <= 0:
		die()