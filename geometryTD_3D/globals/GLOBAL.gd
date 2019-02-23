extends Node

func randomId():
	randomize()
	return randi() % 999999

func addOrRemoveAngleToDir(boolAdd,Vector2Dir,toAdd):
	var oldAngle  = Vector2Dir.angle()
	var newAngle
	if boolAdd:
		newAngle  = oldAngle + toAdd
	else:
		newAngle  = oldAngle - toAdd
	return Vector2(sin(newAngle),cos(newAngle))