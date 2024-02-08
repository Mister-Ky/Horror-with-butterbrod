class_name GameObject
extends Spatial

func _ready():
	pass

func getPosition() -> Vector3:
	return global_transform.origin
