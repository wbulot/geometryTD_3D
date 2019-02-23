extends KinematicBody

var id = 0

onready var tower = get_node(".")

#We need to init dir and targetdir because character will rotate as soon as it is live, following dir direction
#So these variable can't be null or 0. We init them as same value than init facing direction
onready var targetDir = (transform.origin + transform.basis.z.normalized()) - transform.origin
onready var dir = (transform.origin + transform.basis.z.normalized()) - transform.origin

var isLocal = false
var isInit = 0
var isGodMode = 0
var isAlive = 0
var isAttacking = 0

var life = 100
var team = 0

var target
var targetPos = Vector3()

var shootTimer = 0
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
			calcTargetDir()
			
			calcRotation()
			
			processSmoothRotate(delta)
			
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
	$"..".clientRelay_updateObjectPosition("tower",id,transform)

func calcTargetDir():
	targetDir = targetDir.normalized()

func calcRotation():
	#We set the rotation acording to the face direction
	var angle = atan2(dir.x, dir.z)
	var playerRot = tower.get_rotation();
	playerRot.y = angle
	tower.set_rotation(playerRot);

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

func checkEnemies():
	target = null
	var direction = tower.get_transform().basis.z.normalized()
	
	var allUnits = get_tree().get_nodes_in_group("unit")
	for unit in allUnits:
		if unit.isAlive && unit.team != tower.team && unit.team != 0:
			var towerToEnemy = unit.transform.origin - tower.transform.origin
			if towerToEnemy.length() < 10:
				var enemyDirection = unit.get_transform().basis.z.normalized()
				var dot_product = direction.dot(towerToEnemy.normalized())
				if rad2deg(direction.angle_to(towerToEnemy.normalized())) < 180:
					#Check raycast view
					var lineOfSightDir = (unit.transform.origin - tower.transform.origin).normalized()
					var rayCastResult = get_world().direct_space_state.intersect_ray(tower.transform.origin + Vector3(0,1,0),unit.transform.origin + Vector3(0,1,0),[self,unit])
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

func die():
	if isAlive: #Unit will be considered dead at the next frame
		var material = SpatialMaterial.new()
		material.albedo_color = Color(0,0,0)
		$MeshInstance.set_material_override(material)
		$Particles.emitting = true

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