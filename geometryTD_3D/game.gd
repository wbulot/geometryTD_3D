extends Spatial

var title = "Game v0.1"

var team
var gameStarted = false

#For FPS Counter
const TIMER_LIMIT = 0.05
var timer = 0.0

#For touch screen behavior
var touchStartPos = Vector2()
var touchEndPos = Vector2()

#UI
onready var spawnUnitBtn = $"../clientUi/inGame/spawnUnit"
onready var buildTowerBtn = $"../clientUi/inGame/buildTower"

#Tower
var isPlaceTower = false

func _ready():
	spawnUnitBtn.connect("pressed", self, "client_AddObject",["unit"])
	buildTowerBtn.connect("pressed", self, "placeTower")
	pass

func joinServer(server):
	$"../clientUi/lobby/networkState".text = "CONNECTING ..."
	var client = NetworkedMultiplayerENet.new()
	client.create_client(server,8888)
	get_tree().set_network_peer(client)
	client.connect("connection_failed",self,"_connection_failed")
	client.connect("connection_succeeded",self,"_connection_succeeded")

func _connection_failed():
	$"../clientUi/lobby/networkState".text = "ERROR"

func _connection_succeeded():
	$"../clientUi/lobby/networkState".text = "CONNECTED"

func _input(event):
	if event is InputEventKey && event.pressed:
		if (event.scancode == KEY_ESCAPE):
			get_tree().quit();
	if event is InputEventScreenTouch && OS.get_name() == "Android":
		if event.is_pressed():
			touchStartPos = event.position
		else:
			touchEndPos = event.position
#			if touchStartPos == touchEndPos:
#				if gameStarted:
#					client_AddUnit(event)
				
	if event is InputEventMouseButton && Input.is_mouse_button_pressed(BUTTON_LEFT) && OS.get_name() == "Windows":
		if gameStarted:
			if isPlaceTower:
				buildTower(event)
				isPlaceTower = false
	
func _process(delta):
	timer += delta
	if timer > TIMER_LIMIT:
		timer = 0.0
		OS.set_window_title(title + " | fps: " + str(Engine.get_frames_per_second()))
		$"../clientUi/fps".text = str(Engine.get_frames_per_second())

func processGameState(gameState):
	for nodeName in gameState:
			if typeof(gameState[nodeName]) == TYPE_DICTIONARY && gameState[nodeName].size() > 0:
				if typeof(nodeName) == TYPE_STRING && nodeName == "unit":
					for objectId in gameState[nodeName]:
						var folder = "res://assets/units/"
						var node = load(str(folder)+str(nodeName)+".tscn").instance()
						node.id = objectId
						node.set_name("unit"+str(objectId))
						for info in gameState[nodeName][objectId]:
							if info == "team":
								node.team = gameState[nodeName][objectId][info]
								if node.team == team:
									node.isLocal = true
							if info == "position":
								node.transform = gameState[nodeName][objectId][info]
						add_child(node)
						node.initUnit()
				if typeof(nodeName) == TYPE_STRING && nodeName == "tower":
					for objectId in gameState[nodeName]:
						var folder = "res://assets/towers/"
						var node = load(str(folder)+str(nodeName)+".tscn").instance()
						node.id = objectId
						node.set_name("tower"+str(objectId))
						for info in gameState[nodeName][objectId]:
							if info == "team":
								node.team = gameState[nodeName][objectId][info]
								if node.team == team:
									node.isLocal = true
							if info == "position":
								node.transform = gameState[nodeName][objectId][info]
						add_child(node)
						node.initUnit()

####
#Functions called localy by client
####

func client_AddObject(objectType):
#	var cameraPos
#	var cameraPosToMouse
#	if OS.get_name() == "Android":
##		cameraPos = $"cameraRoot/camera".project_ray_origin(get_viewport().get_visible_rect().size/2)
##		cameraPosToMouse = cameraPos + $"cameraRoot/camera".project_ray_normal(get_viewport().get_visible_rect().size/2) * 1000
#		cameraPos = $"cameraRoot/camera".project_ray_origin(event.position)
#		cameraPosToMouse = cameraPos + $"cameraRoot/camera".project_ray_normal(event.position) * 1000
#	if OS.get_name() == "Windows":
#		cameraPos = $"cameraRoot/camera".project_ray_origin(event.position)
#		cameraPosToMouse = cameraPos + $"cameraRoot/camera".project_ray_normal(event.position) * 1000
#	var rayCastDir = (cameraPosToMouse - cameraPos).normalized()
#	var rayCastResult = get_world().direct_space_state.intersect_ray(cameraPos,cameraPosToMouse)
#	if(rayCastResult):
#		var objectId = GLOBAL.randomId()
#		var objectPositionOrigin = rayCastResult.position
#		#We calc and pass the angle direction of the raycast to init the right rotation of the unit later
#		var rayCastDirangle = atan2(rayCastDir.x, rayCastDir.z)
#		rpc_id(1,"client_AddUnit",get_tree().get_network_unique_id(),objectId,objectPositionOrigin, rayCastDirangle)
		var objectId = GLOBAL.randomId()
		var teamStartPos = get_node("level/teamArea/team"+str(team))
		var objectPositionOrigin = teamStartPos.transform.origin
		rpc_id(1,"client_AddObject",get_tree().get_network_unique_id(),objectId,objectType,objectPositionOrigin, 0)

func placeTower():
	isPlaceTower = true

func buildTower(event):
	var cameraPos
	var cameraPosToMouse
	if OS.get_name() == "Windows":
		cameraPos = $"cameraRoot/camera".project_ray_origin(event.position)
		cameraPosToMouse = cameraPos + $"cameraRoot/camera".project_ray_normal(event.position) * 1000
		var rayCastDir = (cameraPosToMouse - cameraPos).normalized()
		var rayCastResult = get_world().direct_space_state.intersect_ray(cameraPos,cameraPosToMouse)
		if(rayCastResult):
			##Get grid pos
			var gridMap = get_node("level/navigation/gridMap")
			var cell = gridMap.world_to_map(rayCastResult.position)
			var cellCoord = gridMap.map_to_world(cell.x,cell.y,cell.z)

			var objectId = GLOBAL.randomId()
			var objectPositionOrigin = cellCoord

			rpc_id(1,"client_AddObject",get_tree().get_network_unique_id(),objectId,"tower",objectPositionOrigin, 0)
			

func clientRelay_updateObjectPosition(objectType,objectId,position):
	rpc_id(1,"client_updateObjectPosition",objectType,objectId,position)

func clientRelay_unitEnterTerritory(unitId,area):
	rpc_id(1,"client_UnitEnterTerritory",unitId,area)

####
#Functions called remotely by server
####
remote func server_InitPlayer(sTeam):
	gameStarted = true
	#We assign the team to the player
	team = sTeam
	#We hide the lobby
	$"../clientUi/lobby".hide()
	#We show the inGame ui
	$"../clientUi/inGame".show()
	$"../clientUi/inGame/team".text = "TEAM "+str(team)
	#We instance the level
	add_child(preload("res://level/level.tscn").instance())
	#We create the camera
	add_child(preload("res://level/cameraRoot.tscn").instance())
	#We move the camera according to the team of the player
	$"cameraRoot".transform.origin = get_node("level/teamArea/team"+str(team)).transform.origin + Vector3(0,30,0) + ($"cameraRoot/camera".transform.basis.z*10)
	#We rotate the camera to the center of the level
	$"cameraRoot".look_at($"level".transform.origin,Vector3(0,1,0))
	$"cameraRoot".rotation_degrees.x = -56.25

remote func server_SyncGameState(gameState):
	processGameState(gameState)

remote func server_AddObject(sPlayerId,sObjectId,sObjectType,sPosition,sTeam):
	var object
	if sObjectType == "unit":
		object = load("res://assets/units/unit.tscn").instance()
	if sObjectType == "tower":
		object = load("res://assets/towers/tower.tscn").instance()
	object.id = sObjectId
	object.set_name(str(sObjectType)+str(sObjectId))
	object.transform = sPosition
	object.team = sTeam
	if team == sTeam:
		object.isLocal = true
	add_child(object)
	object.initUnit()

remote func server_removeObject(type,objectId):
	get_node(type+str(objectId)).queue_free()
	
remote func server_updateObjectPosition(type,objectId,position):
	if has_node(type+str(objectId)) && team != get_node(type+str(objectId)).team:
		get_node(type+str(objectId)).transform = position