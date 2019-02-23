extends Area

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_teamArea_body_entered(body):
	if body.get_class() == "KinematicBody":
		if body.isLocal && get_name() != "team"+str(body.team):
			$"../../../".clientRelay_unitEnterTerritory(body.id,get_name())