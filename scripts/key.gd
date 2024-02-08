class_name Key
extends KinematicBody

export(String) var key = ""
export(int) var rotationSpeed = 1

func _ready():
	pass

func get_key() -> String:
	G.debug_print("You have picked up the key - \"" + str(key) + "\"")
	return key

func _physics_process(delta):
	rotation.y += rotationSpeed * delta

func delete():
	queue_free()
