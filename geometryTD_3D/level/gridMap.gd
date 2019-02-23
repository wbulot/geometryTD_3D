extends GridMap

onready var gridMap = $"."
var unitsOnGrid = {}

var aStar
var allPointsInd = {}
var allPointsUnitsCount = {}

func _ready():
	
#	aStar = AStar.new()
#	var cells = get_used_cells()
#	#We do a first pass on the all grid cells to init aStar point and other stuff
#	for cell in cells:
#		#We create aMap grid on the gridmap grid
#		var cellCoord = gridMap.map_to_world(cell.x,cell.y,cell.z)
#		var ind = aStar.get_available_point_id()
#		aStar.add_point(ind,cellCoord)
#		allPointsInd[v3ToIndex(cell)] = ind
#		#We create the area + collision shape for each gridmap cell
#		var shape = BoxShape.new()
#		shape.set_extents(Vector3(1,1,1))
#		var collision = CollisionShape.new()
#		collision.set_shape(shape)
#		var nodeArea = Area.new()
#		nodeArea.transform.origin = cellCoord
#		nodeArea.add_child(collision)
#		add_child(nodeArea)
#		nodeArea.connect("body_entered", self, "_body_entered2",[nodeArea,Vector3(cell.x,cell.y,cell.z)])
#		nodeArea.connect("body_exited", self, "_body_exited2",[nodeArea,Vector3(cell.x,cell.y,cell.z)])
#		#we ini the number of player on each cell with 0
#		allPointsUnitsCount[v3ToIndex(cell)] = 0
#
#	#We do a second pass this time to connect all astar point on each others
#	for cell in cells:
#		for x in [-1, 0, 1]:
#			for y in [-1, 0, 1]:
#				for z in [-1, 0, 1]:
#					var v3 = Vector3(x,y,z)
#					if v3 == Vector3(0,0,0):
#						continue
#					if v3ToIndex(v3+cell) in allPointsInd:
#						var ind1 = allPointsInd[v3ToIndex(cell)]
#						var ind2 = allPointsInd[v3ToIndex(cell + v3)]
#						if !aStar.are_points_connected(ind1,ind2):
#							aStar.connect_points(ind1,ind2,true)
	
	var cells = gridMap.get_used_cells()
	for cell in cells:
		var cellCoord = gridMap.map_to_world(cell.x,cell.y,cell.z)
		var groundTile = preload("res://level/groundTile.tscn").instance()
		groundTile.transform.origin = cellCoord
		add_child(groundTile)
		groundTile.get_children()[0].connect("body_entered", self, "_body_entered",[groundTile.get_children()[1]])
		groundTile.get_children()[0].connect("body_exited", self, "_body_exited",[groundTile.get_children()[1]])
		
#func _process(delta):
#	if cellCheckTimer < 0:
#		for node in get_children():
#			if node.get_overlapping_bodies().size() > 0:
#				print(node)
#				node.queue_free()
#		cellCheckTimer = 1
#	else:
#		cellCheckTimer -= delta

#func v3ToIndex(v3):
#	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))

func _body_entered(body,senderNode):
	if body.get_class() == "KinematicBody" && body.team == $"/root/main/game".team:
		var groundNode = senderNode.get_parent()
		var navMeshPath = senderNode.get_parent().get_name()+"/navmesh"
		var navMeshNode = get_node(navMeshPath)
		#we create the dict entry
		if !unitsOnGrid.has(groundNode.get_name()):
			unitsOnGrid[groundNode.get_name()] = 0

		if unitsOnGrid.has(groundNode.get_name()):
			unitsOnGrid[groundNode.get_name()] += 1
#			if unitsOnGrid[groundNode.get_name()] >= 2:
#				navMeshNode.enabled = false
#				groundNode.hide()
#				print(str(unitsOnGrid[groundNode.get_name()])+"Units disableMesh")

#func _body_entered2(body,senderArea,cell):
#	if body.get_class() == "KinematicBody" && body.team == $"/root/main/game".team:
#		allPointsUnitsCount[v3ToIndex(cell)] += 1
#		if allPointsUnitsCount[v3ToIndex(cell)] > 0:
			#We disable the astar cell there
#			senderArea.hide()
#			for x in [-1, 0, 1]:
#				for y in [-1, 0, 1]:
#					for z in [-1, 0, 1]:
#						var v3 = Vector3(x,y,z)
#						if v3 == Vector3(0,0,0):
#							continue
#						if v3ToIndex(v3+cell) in allPointsInd:
#							var ind1 = allPointsInd[v3ToIndex(cell)]
#							var ind2 = allPointsInd[v3ToIndex(cell + v3)]
#							if aStar.are_points_connected(ind1,ind2):
#								aStar.disconnect_points(ind1,ind2)

func _body_exited(body,senderNode):
	if body.get_class() == "KinematicBody" && body.team == $"/root/main/game".team:
		var groundNode = senderNode.get_parent()
		var navMeshPath = senderNode.get_parent().get_name()+"/navmesh"
		var navMeshNode = get_node(navMeshPath)
		if unitsOnGrid.has(groundNode.get_name()):
			unitsOnGrid[groundNode.get_name()] -= 1
#			if unitsOnGrid[groundNode.get_name()] < 2:
#				navMeshNode.enabled = true
#				groundNode.show()
#				print("enableMesh")

#func _body_exited2(body,senderArea,cell):
#	if body.get_class() == "KinematicBody" && body.team == $"/root/main/game".team:
#		allPointsUnitsCount[v3ToIndex(cell)] -= 1
#		if allPointsUnitsCount[v3ToIndex(cell)] == 0:
#			senderArea.show()
			#We enable the astar cell
#			for x in [-1, 0, 1]:
#				for y in [-1, 0, 1]:
#					for z in [-1, 0, 1]:
#						var v3 = Vector3(x,y,z)
#						if v3 == Vector3(0,0,0):
#							continue
#						if v3ToIndex(v3+cell) in allPointsInd:
#							var ind1 = allPointsInd[v3ToIndex(cell)]
#							var ind2 = allPointsInd[v3ToIndex(cell + v3)]
#							if !aStar.are_points_connected(ind1,ind2):
#								aStar.connect_points(ind1,ind2,true)

#func getPath(start, end):
#	var startId = 0
#	var endId = 0
#
#	startId = aStar.get_closest_point(start)
#	endId = aStar.get_closest_point(end)
#
#	return aStar.get_point_path(startId, endId)

#func isCellAvailable(pos):
#	var cell = gridMap.world_to_map(pos)
#	#If there is already a player on the cell, it is not available to move on
#	if allPointsUnitsCount[v3ToIndex(cell)] > 0:
#		return false
#	else:
#		return true