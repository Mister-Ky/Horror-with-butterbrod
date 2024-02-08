extends Node

export(bool) var mods_enabled = true
var mods = {}
const lms_path = "res://mods/load_mods.lms"

func _ready():
	pass

func start():
	if mods_enabled:
		G.debug_print("The mods have started loading")
		G.debug_print()
		_load_mods(lms_path)
		G.debug_print("The loading of mods is complete")
		G.debug_print()

func _checkNodePath(node_path) -> bool:
	var node = get_node(node_path)
	return (not node == self and not node == G.getG())

func _checkComment(line) -> bool:
	if line == "" or line.begins_with("#") or line.begins_with(";"):
		return true
	return false

func _load_mods(path):
	var file = File.new()
	if file.file_exists(path):
		file.open(path, File.READ)
		while !file.eof_reached():
			var line = file.get_line().strip_edges()
			if _checkComment(line):
				continue
			_load_mod(line)
		file.close()
	else:
		G.debug_print("Mod loader file \"" + str(path) + "\" not found")

func _load_mod(mod):
	var file = File.new()
	if file.file_exists(mod):
		file.open(mod, File.READ)
		var mod_name = file.get_line().strip_edges()
		mods[mod_name] = {"path": mod, "resources": []}
		G.debug_print("The loading of the mod \"" + str(mod_name) + "\" has started")
		while !file.eof_reached():
			var line = file.get_line().strip_edges()
			if _checkComment(line):
				continue
			var parts = line.split(" | ")
			var resource_path = parts[0]
			var resource_type = parts[1]
			var node_path = null
			if parts.size() > 2:
				node_path = parts[2]
			_load_res(mod_name, resource_path, resource_type, node_path)
		G.debug_print("The mod \"" + str(mod_name) + "\" is loaded")
		G.debug_print()
		file.close()
	else:
		G.debug_print("Target mod file \"" + str(mod) + "\" not found")

func _load_res(mod_name, res_path, res_type, node_path):
	if node_path != null:
		if not _checkNodePath(node_path):
			return
	var file = File.new()
	if file.file_exists(res_path):
		var res = load(res_path)
		mods[mod_name]["resources"].append(res)
		if res_type == "SCENE":
			var parent_node = get_tree().root
			if node_path != null:
				parent_node = get_node(node_path)
			var res_scene = res.instance()
			parent_node.call_deferred("add_child", res_scene)
		elif res_type == "GDSCRIPT":
			var node : Node = get_node(node_path)
			if node:
				node.set_script(res)
			else:
				G.debug_print("It is forbidden to overwrite the current global script")
				G.debug_print("The resource \"" + str(res_path) + "\" of the mod \"" + str(mod_name) + "\" failed to load")
				return
		elif res_type == "GDSCRIPT*AUTOLOAD":
			pass
		elif res_type == "CHANGING*VISIBILITY":
			var node : Node = get_node(node_path)
			if node:
				node.visible = not node.visible
		elif res_type == "DELETE":
			var node : Node = get_node(node_path)
			if node:
				node.queue_free()
		G.debug_print("The resource \"" + str(res_path) + "\" of the mod \"" + str(mod_name) + "\" is loaded")
	else:
		G.debug_print("The resource \"" + str(res_path) + "\" of the mod \"" + str(mod_name) + "\" not found")
