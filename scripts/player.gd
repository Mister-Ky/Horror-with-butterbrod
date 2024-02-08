class_name Player
extends KinematicBody

export(String) var player_name = "player"
export(float) var SPEED = 200.0
export(float) var SPEED_WITH_SHIFT = 2.0
export(float) var JUMP_VELOCITY = 8.0
export(float, 0.1, 1) var mouse_sensitivity = 0.1
export(NodePath) var nmesh_path
export(NodePath) var viewport_path

onready var camera = $camera
onready var raycast = $camera/ray_cast
onready var lamp = $camera/hand/lamp
onready var label = $ui/label

var keys = []
var vel = Vector3()

func _ready():
	camera.environment.background_sky.set_panorama(get_node(viewport_path).get_viewport().get_texture())
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func checkKeyExists(searchKey: String) -> bool:
	for key in keys:
		if key == searchKey:
			return true
	return false

func removeKey(value: String):
	var index := -1
	for i in range(keys.size()):
		if keys[i] == value:
			index = i
			break
	if index != -1:
		keys.remove(index)

func _input(event):
	if event is InputEventMouseMotion and event.relative:
		var mouse_motion = event.relative
		rotate_y(deg2rad(-mouse_motion.x * mouse_sensitivity))
		
		var new_rotation = camera.rotation_degrees.x - mouse_motion.y * mouse_sensitivity
		if new_rotation > -80 and new_rotation < 80:
			camera.rotate_x(deg2rad(-mouse_motion.y * mouse_sensitivity))
	
	var resultRayCast = raycast.get_collider()
	if resultRayCast:
		var key_string_action_player = KeysSystem.get_first_key_string_from_action_event("action_player").to_upper()
		
		if resultRayCast is Door:
			if resultRayCast.lockActive:
				label.text = "Press the " + key_string_action_player + " key to remove the lock"
			elif resultRayCast.isOpen:
				label.text = "Press the " + key_string_action_player + " key to close the door"
			else:
				label.text = "Press the " + key_string_action_player + " key to open the door"
			if Input.is_action_just_pressed("action_player"):
				if resultRayCast.lockActive:
					if resultRayCast.requiredKey != "" and not resultRayCast.isOpen:
						if checkKeyExists(resultRayCast.requiredKey):
							removeKey(resultRayCast.requiredKey)
							resultRayCast.requiredKey = ""
							G.debug_print("You took the lock off the door - \"" + str(resultRayCast.name_door) + "\"")
						else:
							G.debug_print("This door (the name of the door - \"" + str(resultRayCast.name_door) + "\") requires key - \"" + resultRayCast.requiredKey + "\"")
				else:
					resultRayCast.interactWithDoor(global_transform.origin)
					#var nmesh : NavigationMeshInstance = get_node(nmesh_path)
					#nmesh.bake_navigation_mesh()
		elif resultRayCast is Key:
			label.text = "Press the " + key_string_action_player + " key to get the key"
			if Input.is_action_just_pressed("action_player"):
				keys.append(resultRayCast.get_key())
				resultRayCast.delete()
		else:
			label.text = ""
	else:
		label.text = ""
	
	if Input.is_action_just_pressed("lamp"):
		lamp.visible = not lamp.visible

func _physics_process(delta):
	if not is_on_floor():
		vel.y -= G.gravity * delta
	elif Input.is_action_pressed("space"):
		vel.y += JUMP_VELOCITY
	
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var shift_speed = 1
	if Input.is_action_pressed("shift"):
		shift_speed = SPEED_WITH_SHIFT
	if direction:
		vel.x = direction.x * SPEED * shift_speed * delta
		vel.z = direction.z * SPEED * shift_speed * delta
	else:
		vel.x = move_toward(vel.x, 0, SPEED)
		vel.z = move_toward(vel.z, 0, SPEED)
	
	vel = move_and_slide(vel, Vector3.UP)
