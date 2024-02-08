extends Spatial

export(int, 1, 600) var day_length = 600
export(NodePath) var sky_shader_path
onready var sky_shader = get_node(sky_shader_path)
var iTime = 0.0
var iFrame = 0
var hour = 0
var minute = 0
var prev_time = -1

func _ready():
	sky_shader.cov_scb(0.5)
	sky_shader.absb_scb(1)
	sky_shader.thick_scb(25)
	sky_shader.step_scb(25)
	sky_shader.DAY_TIME_scb(0)
	sky_shader.wind_strength(max(0.05, (10 / day_length)))

func _physics_process(delta):
	iTime += delta
	iFrame += 1
	
	var progress = fmod(iTime, day_length) / day_length
	sky_shader.DAY_TIME_scb(progress)
	
	$light.rotation.x = PI * (2 * progress - 1.5)
	
	var time = progress * 24
	hour = int(time)
	minute = int((time - hour) * 60)
	if minute != prev_time:
		G.debug_print("Time - \"" + str(hour) + ":" + str(minute) + "\"")
		prev_time = minute
