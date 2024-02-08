extends Node

var key_config_file = "user://keys.ini"
var actions = {}

func _ready():
	pass

func change_action(action_name : String):
	if InputMap.has_action(action_name) and actions.has(action_name):
		var keys = actions[action_name]
		var event = InputEventKey.new()
		for key in keys:
			event.scancode = key
			InputMap.action_add_event(action_name, event)

func actions_clear():
	actions.clear()

func change_all_actions():
	for action in actions.keys:
		change_action(action)

func clear_all_actions():
	for action in actions.keys:
		clear_action(action)

func clear_action(action_name : String):
	if InputMap.has_action(action_name):
		InputMap.action_erase_events(action_name)

func get_first_key_string_from_action_event(action_name : String) -> String:
	var key_string = ""
	var keys = InputMap.get_action_list(action_name)
	if keys.size() > 0:
		var key = keys[0]
		if key is InputEventKey:
			key_string = OS.get_scancode_string(key.scancode)
	return key_string

func save_key(key_name : String, key_codes : Array):
	var file = File.new()
	file.open(key_config_file, File.WRITE)
	var key_codes_str = []
	for code in key_codes:
		key_codes_str.append(str(code))
	file.store_line(key_name + "=" + "*".join(key_codes_str))
	file.close()

func load_all_keys():
	var file = File.new()
	if file.file_exists(key_config_file):
		file.open(key_config_file, File.READ)
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			var parts = line.split("=")
			if parts.size() == 2:
				var action_name = parts[0]
				var keys = []
				for key in parts[1].split("*"):
					keys.append(int(key))
				actions[action_name] = keys
		file.close()
