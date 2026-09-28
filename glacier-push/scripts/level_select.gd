extends Control

const JuicyScript = preload("res://scripts/juicy.gd")
const COLS: int = 5

@onready var grid: GridContainer = %LevelGrid
@onready var premium_label: Label = %PremiumLabel
@onready var background: ColorRect = $Background
@onready var back_button: Button = %BackButton
@onready var premium_button: Button = %PremiumButton
@onready var title: Label = %Title
@onready var mode_row: HBoxContainer = %ModeRow


func _ready() -> void:
	var colors: Dictionary = JuicyScript.palette()
	background.color = colors["sky_top"]
	title.add_theme_color_override("font_color", colors["text_dark"])
	title.add_theme_font_size_override("font_size", 40)
	premium_label.add_theme_color_override("font_color", colors["text_dark"])
	JuicyScript.style_button(back_button, colors["wall"], 26)
	JuicyScript.style_button(premium_button, colors["premium"], 22)
	_build_mode_tabs()
	_refresh()


func _build_mode_tabs() -> void:
	for child in mode_row.get_children():
		child.queue_free()
	for mode in GameState.MODES:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 64)
		btn.text = GameState.mode_label(mode)
		btn.focus_mode = Control.FOCUS_NONE
		var col := Color("4CD964")
		if mode == "hard":
			col = Color("FF9F0A")
		elif mode == "crazy":
			col = Color("FF2D55")
		JuicyScript.style_button(btn, col, 26)
		btn.pressed.connect(_on_mode_tab.bind(mode))
		mode_row.add_child(btn)


func _on_mode_tab(mode: String) -> void:
	GameState.set_mode(mode)
	_refresh()


func _refresh() -> void:
	title.text = "%s Levels" % GameState.mode_label()
	premium_label.text = (
		"Premium unlocked"
		if GameState.is_premium
		else "Remove ads · $1.99"
	)
	for child in grid.get_children():
		child.queue_free()
	grid.columns = COLS
	var colors: Dictionary = JuicyScript.palette()
	for i in range(1, GameState.LEVEL_COUNT + 1):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(160, 96)
		btn.text = str(i)
		btn.focus_mode = Control.FOCUS_NONE
		var unlocked: bool = GameState.is_level_unlocked(i)
		btn.disabled = not unlocked
		var col: Color = colors["play"]
		match GameState.current_mode:
			"hard":
				col = colors["premium"]
			"crazy":
				col = Color("FF2D55")
			_:
				col = Color("4CD964")
		JuicyScript.style_button(btn, col if unlocked else col.darkened(0.35), 28)
		if unlocked:
			btn.pressed.connect(_open_level.bind(i))
		grid.add_child(btn)


func _open_level(level_id: int) -> void:
	GameState.start_level(level_id)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_premium_pressed() -> void:
	Monetization.buy_full_game_unlock()
	_refresh()
