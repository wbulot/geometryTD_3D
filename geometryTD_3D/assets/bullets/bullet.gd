extends RigidBody

var id

var bullet
var prev_pos
var velocity
var distBullet = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	bullet = get_node(".")
	prev_pos = bullet.get_transform().origin

func _process(delta):
	pass

func _physics_process(delta):
	if distBullet > 100:
		rpc_id(1,"removeBullet")
		queue_free()
	var bulletPos = bullet.get_transform().origin
	if (bulletPos != Vector3(0,0,0)):
		velocity = (bullet.get_transform().origin - prev_pos)/delta
#		DrawLine3D.DrawLine(bulletPos, prev_pos, Color(1, 0, 0), 10)
#		var rayCastResult = get_world().direct_space_state.intersect_ray(prev_pos, bulletPos,[self],4)
		var rayCastResult = get_world().direct_space_state.intersect_ray(prev_pos, bulletPos,[self])
		if rayCastResult:
#			print(rayCastResult.collider.get_class())
			if rayCastResult.collider.get_class() == "KinematicBody":
				print("hit unit")
				rpc_id(1,"hit",rayCastResult.collider.id,"other")
			if rayCastResult.collider.get_class() == "RigidBody":
				print(velocity.length())
				rayCastResult.collider.apply_impulse(Vector3(0,0,0),velocity * (bullet.mass/rayCastResult.collider.mass))
				queue_free()
		var tempDist = prev_pos - bulletPos
		distBullet += tempDist.length()
		prev_pos = bullet.get_transform().origin
	
#	var bulletDir = velocity.normalized()
#	DrawLine3D.DrawLine(bulletPos, bulletPos + bulletDir, Color(1, 0, 0), 30)