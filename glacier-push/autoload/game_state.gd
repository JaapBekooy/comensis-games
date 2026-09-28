extends Node

const SAVE_PATH: String = "user://glacier_push.cfg"
const LEVEL_COUNT: int = 50
const MODES: PackedStringArray = ["easy", "hard", "crazy"]

var current_mode: String = "easy"
var current_level: int = 1
## Per-mode progress
var highest_unlocked: Dictionary = {"easy": 1, "hard": 1, "crazy": 1}
var levels_completed: Dictionary = {"easy": 0, "hard": 0, "crazy": 0}
var is_premium: bool = false
var selected_character: String = "polar_bear"


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	var cfg := ConfigFile.new()
	var err: int = cfg.load(SAVE_PATH)
	if err != OK:
		return
	current_mode = String(cfg.get_value("progress", "current_mode", "easy"))
	if current_mode not in MODES:
		current_mode = "easy"
	for mode in MODES:
		highest_unlocked[mode] = int(cfg.get_value("progress", "unlock_%s" % mode, 1))
		levels_completed[mode] = int(cfg.get_value("progress", "clears_%s" % mode, 0))
	is_premium = bool(cfg.get_value("progress", "is_premium", false))
	selected_character = String(cfg.get_value("progress", "selected_character", "polar_bear"))


func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_mode", current_mode)
	for mode in MODES:
		cfg.set_value("progress", "unlock_%s" % mode, int(highest_unlocked.get(mode, 1)))
		cfg.set_value("progress", "clears_%s" % mode, int(levels_completed.get(mode, 0)))
	cfg.set_value("progress", "is_premium", is_premium)
	cfg.set_value("progress", "selected_character", selected_character)
	cfg.save(SAVE_PATH)


func set_mode(mode: String) -> void:
	if mode in MODES:
		current_mode = mode
		save_progress()


func start_level(level_id: int) -> void:
	current_level = clampi(level_id, 1, LEVEL_COUNT)


func continue_level() -> int:
	return clampi(int(highest_unlocked.get(current_mode, 1)), 1, LEVEL_COUNT)


func has_progress() -> bool:
	for mode in MODES:
		if int(highest_unlocked.get(mode, 1)) > 1 or int(levels_completed.get(mode, 0)) > 0:
			return true
	return false


func is_level_unlocked(level_id: int) -> bool:
	return level_id <= int(highest_unlocked.get(current_mode, 1))


func on_level_cleared(level_id: int) -> void:
	var clears: int = int(levels_completed.get(current_mode, 0)) + 1
	levels_completed[current_mode] = clears
	var unlocked: int = int(highest_unlocked.get(current_mode, 1))
	if level_id >= unlocked and level_id < LEVEL_COUNT:
		highest_unlocked[current_mode] = level_id + 1
	elif level_id == LEVEL_COUNT:
		highest_unlocked[current_mode] = LEVEL_COUNT
	save_progress()
	var total_clears: int = 0
	for mode in MODES:
		total_clears += int(levels_completed.get(mode, 0))
	Monetization.on_level_complete(level_id, total_clears)


func set_premium(enabled: bool) -> void:
	is_premium = enabled
	save_progress()
	Monetization.apply_premium_status(enabled)


func mode_label(mode: String = "") -> String:
	var m: String = mode if mode != "" else current_mode
	match m:
		"easy":
			return "Easy"
		"hard":
			return "Hard"
		"crazy":
			return "Crazy"
		_:
			return m.capitalize()
