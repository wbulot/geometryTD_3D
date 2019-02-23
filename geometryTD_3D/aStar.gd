extends Spatial
#
#var allPoints = {}
#var aStar = null
#onready var gridMap = $GridMap
#
#func _ready():
#	aStar = AStar.new()
#	var cells = gridMap.get_used_cells()
#	for cell in cells:
#		var ind = aStar.get_available_point_id()
#		aStar.add_point(ind,gridMap.map_to_world(cell.x,cell.y,cell.z))
#		allPoints[v3ToIndex(cell)] = ind
#	for cell in cells:
#		for x in [-1, 0, 1]:
#			for y in [-1, 0, 1]:
#				for z in [-1, 0, 1]:
#					var v3 = Vector3(x,y,z)
#					if v3 == Vector3(0,0,0):
#						continue
#					if v3ToIndex(v3+cell) in allPoints:
#						var ind1 = allPoints[v3ToIndex(cell)]
#						var ind2 = allPoints[v3ToIndex(cell + v3)]
#						if !aStar.are_points_connected(ind1,ind2):
#							aStar.connect_points(ind1,ind2,true)
#
#func v3ToIndex(v3):
#	return str(int(round(v3.x))) + "," + str(int(round(v3.y))) + "," + str(int(round(v3.z)))
#
#func getPath(start, end):
#	var startId = 0
#	var endId = 0
#
#	startId = aStar.get_closest_point(start)
#
#	endId = aStar.get_closest_point(end)
#
#	return aStar.get_point_path(startId, endId)