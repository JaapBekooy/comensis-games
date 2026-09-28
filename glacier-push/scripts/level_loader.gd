class_name LevelLoader
extends RefCounted

const LEVEL_ROOT: String = "res://levels/"


static func load_level(level_id: int, mode: String = "") -> Dictionary:
	var m: String = mode if mode != "" else GameState.current_mode
	var path: String = "%s%s/level_%03d.json" % [LEVEL_ROOT, m, level_id]
	if not FileAccess.file_exists(path):
		push_error("Level missing: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open level: %s" % path)
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid level JSON: %s" % path)
		return {}
	var dict: Dictionary = data
	dict["id"] = level_id
	dict["mode"] = m
	return dict


static func level_exists(level_id: int, mode: String = "") -> bool:
	var m: String = mode if mode != "" else GameState.current_mode
	return FileAccess.file_exists("%s%s/level_%03d.json" % [LEVEL_ROOT, m, level_id])
