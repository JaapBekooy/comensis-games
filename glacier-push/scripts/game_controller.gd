extends Control

const BoardLogicScript = preload("res://scripts/board_logic.gd")
const BoardViewScript = preload("res://scripts/board_view.gd")
const InputRouterScript = preload("res://scripts/input_router.gd")
const LevelLoaderScript = preload("res://scripts/level_loader.gd")
const JuicyScript = preload("res://scripts/juicy.gd")

@onready var safe_margin: MarginContainer = %SafeMargin
@onready var board_host: Control = %BoardHost
@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var win_panel: PanelContainer = %WinPanel
@onready var hint_label: Label = %HintLabel
@onready var background: ColorRect = $Background
@onready var undo_button: Button = %UndoButton
@onready var restart_button: Button = %RestartButton
@onready var hint_button: Button = %HintButton
@onready var menu_button: Button = %MenuButton
@onready var next_button: Button = %NextButton
@onready var win_menu_button: Button = %WinMenuButton
@onready var win_title: Label = %WinTitle

var logic: BoardLogic
var view: BoardView
var input_router: InputRouter
var level_data: Dictionary = {}
var ice_material: ShaderMaterial
var _colors: Dictionary = {}


func _ready() -> void:
	_colors = JuicyScript.palette()
	AudioManager.start_music()
	_apply_safe_margins()
	_setup_shader()
	_style_ui()
	input_router = InputRouterScript.new()
	add_child(input_router)
	input_router.move_requested.connect(_on_move)
	input_router.undo_requested.connect(_on_undo)
	input_router.restart_requested.connect(_on_restart)
	Monetization.rewarded_hint_granted.connect(_on_hint_granted)
	_load_current_level()


func _style_ui() -> void:
	background.color = _colors["sky_top"]
	title_label.add_theme_color_override("font_color", _colors["text_dark"])
	title_label.add_theme_font_size_override("font_size", 42)
	status_label.add_theme_color_override("font_color", _colors["text_dark"])
	hint_label.add_theme_color_override("font_color", _colors["play"])
	JuicyScript.style_button(undo_button, _colors["continue"], 28)
	JuicyScript.style_button(restart_button, _colors["secondary"], 28)
	JuicyScript.style_button(hint_button, _colors["premium"], 28)
	JuicyScript.style_button(menu_button, _colors["wall"], 28)
	JuicyScript.style_button(next_button, _colors["play"], 34)
	JuicyScript.style_button(win_menu_button, _colors["continue"], 28)
	win_panel.add_theme_stylebox_override(
		"panel",
		JuicyScript.round_style(_colors["win"], 36.0, 6.0, Color(1, 1, 1, 0.65), 16),
	)
	win_title.add_theme_color_override("font_color", Color.WHITE)
	win_title.add_theme_font_size_override("font_size", 52)


func _apply_safe_margins() -> void:
	## Near full-bleed horizontally so the grid uses screen width.
	safe_margin.add_theme_constant_override("margin_left", 12)
	safe_margin.add_theme_constant_override("margin_right", 12)
	safe_margin.add_theme_constant_override("margin_top", 56)
	safe_margin.add_theme_constant_override("margin_bottom", 24)


func _setup_shader() -> void:
	var shader: Shader = load("res://shaders/ice_block.gdshader") as Shader
	ice_material = ShaderMaterial.new()
	ice_material.shader = shader


func _load_current_level() -> void:
	win_panel.visible = false
	win_panel.scale = Vector2.ONE
	hint_label.text = ""
	level_data = LevelLoaderScript.load_level(GameState.current_level)
	if level_data.is_empty():
		status_label.text = "Missing level file."
		return

	title_label.text = "%s · Level %d" % [GameState.mode_label(), GameState.current_level]
	var subtitle: String = String(level_data.get("name", "Puzzle"))
	status_label.text = subtitle

	if view:
		view.queue_free()
		view = null

	logic = BoardLogicScript.new()
	logic.load_from_dict(level_data)
	logic.level_won.connect(_on_won)

	view = BoardViewScript.new()
	board_host.add_child(view)
	view.setup(logic, ice_material)
	_fit_board_to_width()
	_update_status()
	input_router.enabled = true


func _fit_board_to_width() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if view == null:
		return
	var size: Vector2 = view.grid_pixel_size()
	var host: Vector2 = board_host.size
	if size.x <= 0.0 or host.x <= 0.0:
		return
	## Prefer filling screen width (user request); clamp so it still fits height.
	var scale_w: float = host.x / size.x
	var scale_h: float = host.y / size.y if size.y > 0.0 else scale_w
	var scale_fit: float = minf(scale_w, scale_h)
	## If height allows, bias toward width fill (up to 98% of host width).
	if scale_w <= scale_h * 1.05:
		scale_fit = scale_w * 0.98
	else:
		scale_fit = scale_h * 0.98
	view.scale = Vector2(scale_fit, scale_fit)
	view.position = (host - size * scale_fit) * 0.5


func _on_move(dir: Vector2i) -> void:
	if logic == null or logic.is_animating:
		return
	logic.try_move(dir)
	_update_status()


func _on_undo() -> void:
	if logic and logic.undo():
		view.rebuild_entities()
		_update_status()


func _on_restart() -> void:
	_load_current_level()


func _update_status() -> void:
	if logic == null:
		return
	var name: String = String(level_data.get("name", "Puzzle"))
	status_label.text = "%s · %d / %d" % [name, logic.cubes_on_targets(), logic.count_targets()]


func _on_won() -> void:
	input_router.enabled = false
	AudioManager.play_chime()
	if view:
		view.play_win_fx()
	GameState.on_level_cleared(GameState.current_level)
	win_panel.visible = true
	win_panel.pivot_offset = win_panel.size * 0.5
	win_panel.scale = Vector2(0.5, 0.5)
	win_panel.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(win_panel, "modulate:a", 1.0, 0.2)
	tw.tween_property(win_panel, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	JuicyScript.pulse_forever(next_button, 1.06, 0.8)


func _on_next_pressed() -> void:
	if GameState.current_level < GameState.LEVEL_COUNT:
		GameState.start_level(GameState.current_level + 1)
		_load_current_level()
	else:
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _on_undo_button() -> void:
	_on_undo()


func _on_restart_button() -> void:
	_on_restart()


func _on_hint_pressed() -> void:
	Monetization.request_hint_reward()


func _on_hint_granted() -> void:
	if logic == null:
		return
	for cube in logic.cube_positions:
		if logic.get_floor(cube) != BoardLogic.TILE_TARGET:
			hint_label.text = "Hint: nudge the cube at (%d, %d)" % [cube.x + 1, cube.y + 1]
			return
	hint_label.text = "All set — pop those targets!"
