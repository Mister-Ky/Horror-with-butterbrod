class_name Butterbrod
extends KinematicBody

export(NodePath) var target_path
export(float) var SPEED = 300.0

onready var nav = $nagent
var vel = Vector3()

func _ready():
	pass

func _physics_process(delta):
	var target = get_node(target_path)
	var pos = global_transform.origin
	nav.set_target_location(target.global_transform.origin)
	nav.get_next_location()
	if not nav.is_navigation_finished():
		var target_pos = nav.get_next_location()
		vel = pos.direction_to(target_pos) * SPEED * delta
		nav.set_velocity(vel)


func _on_nagent_velocity_computed(safe_velocity):
	vel = move_and_slide(safe_velocity)
