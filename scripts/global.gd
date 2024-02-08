extends Node

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
export(bool) var debug = OS.is_debug_build()
const conline = "---------------------------------------"

func _ready():
	debug_print(conline)
	debug_print("Program has begun to start")
	debug_print()
	ModSystem.start()
	debug_print("Program has started successfully")
	debug_print(conline)

func getG() -> Node:
	return self

func _unhandled_input(event):
	if Input.is_action_just_pressed("esc"):
		exit(0)
	elif event.is_action_pressed("toggle_fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
		debug_print("Window Fullscreen - \"" + str(OS.window_fullscreen) + "\"")
	elif Input.is_action_just_pressed("test"):
		KeysSystem.load_all_keys()
		KeysSystem.clear_action("action_player")
		KeysSystem.change_action("action_player")

func debug_print(debug_info = null):
	if debug:
		if debug_info:
			print(debug_info)
		else:
			print()

func exit(exit_code : int = -1, comment : String = ""):
	debug_print(conline)
	debug_print("Exit (exit code " + str(exit_code) + ") " + comment)
	get_tree().quit(exit_code)
