class_name Door
extends KinematicBody

export(String) var name_door = "door"
export(String) var requiredKey = ""
var lockActive = false
var isOpen = false
var angle = 0

func _ready():
	if requiredKey != "":
		lockActive = true

func closeDoor():
	angle = 0
	isOpen = false
	G.debug_print("Close door (the name of the door - \"" + str(name_door) + "\")")

func openDoor(player_position):
	var pos = global_transform.origin
	var dir = 1
	if player_position.z < pos.z:
		dir = -1
	angle = deg2rad(90 * dir)
	isOpen = true
	G.debug_print("Open door (the name of the door - \"" + str(name_door) + "\")")

func interactWithDoor(player_position):
	if isOpen:
		closeDoor()
	else:
		openDoor(player_position)

func _physics_process(delta):
	rotation.y = lerp_angle(rotation.y, angle, delta * 4)
	if requiredKey != "":
		lockActive = true
	else:
		lockActive = false
