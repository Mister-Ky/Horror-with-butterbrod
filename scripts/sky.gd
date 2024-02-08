extends Sprite

export(NodePath) var global_v_path
onready var global_v = get_node(global_v_path)

func _ready():
	pass

func _physics_process(_delta):
	self.material.set("shader_param/iTime", global_v.iTime)
	self.material.set("shader_param/iFrame", global_v.iFrame)

func cov_scb(value):
	self.material.set("shader_param/COVERAGE", float(value))

func absb_scb(value):
	self.material.set("shader_param/ABSORPTION", float(value))

func thick_scb(value):
	self.material.set("shader_param/THICKNESS", value)

func step_scb(value):
	self.material.set("shader_param/STEPS", value)

func DAY_TIME_scb(value):
	self.material.set("shader_param/DAY_TIME", value)

func wind_strength(value):
	self.material.set("shader_param/wind_strength", value)
