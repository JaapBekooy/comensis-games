extends Control

const JuicyScript = preload("res://scripts/juicy.gd")

@onready var title_banner: TextureRect = %TitleBanner
@onready var mascot: TextureRect = %Mascot
@onready var easy_button: Button = %EasyButton
@onready var hard_button: Button = %HardButton
@onready var crazy_button: Button = %CrazyButton
@onready var continue_button: Button = %ContinueButton
@onready var levels_button: Button = %LevelsButton
@onready var premium_button: Button = %PremiumButton
@onready var progress_label: Label = %ProgressLabel
@onready var brand_row: HBoxContainer = %BrandRow
@onready var cloud_a: TextureRect = %CloudA
@onready var cloud_b: TextureRect = %CloudB


func _ready() -> void:
	AudioManager.start_music()
	_style_mode_buttons()
	_setup_copy()
	_prepare_intro()
	await get_tree().process_frame
	_play_intro()
	_drift_clouds()


func _style_mode_buttons() -> void:
	JuicyScript.style_button(easy_button, Color("4CD964"), 36)
	JuicyScript.style_button(hard_button, Color("FF9F0A"), 36)
	JuicyScript.style_button(crazy_button, Color("FF2D55"), 36)
	JuicyScript.style_button(continue_button, Color("4DB7FF"), 32)
	JuicyScript.style_button(levels_button, Color("B57CFF"), 30)
	JuicyScript.style_button(premium_button, Color("FFB347"), 26)


func _setup_copy() -> void:
	var has_save: bool = GameState.has_progress()
	continue_button.visible = has_save
	if has_save:
		continue_button.text = "Continue · %s %d" % [
			GameState.mode_label(),
			GameState.continue_level(),
		]
	progress_label.text = "50 puzzles per mode · pick your challenge"


func _prepare_intro() -> void:
	for n in [title_banner, mascot, easy_button, hard_button, crazy_button, continue_button, levels_button, premium_button, progress_label, brand_row]:
		n.modulate.a = 0.0
		n.scale = Vector2(0.75, 0.75)


func _play_intro() -> void:
	for n in [title_banner, mascot, easy_button, hard_button, crazy_button, continue_button, levels_button, premium_button, progress_label, brand_row]:
		if n is Control:
			(n as Control).pivot_offset = (n as Control).size * 0.5
	var delay := 0.05
	for n in [title_banner, mascot, progress_label]:
		JuicyScript.bounce_in(n, delay, 0.6)
		delay += 0.1
	for n in [easy_button, hard_button, crazy_button, continue_button, levels_button, premium_button]:
		if n.visible:
			JuicyScript.bounce_in(n, delay, 0.55)
			delay += 0.08
	JuicyScript.bounce_in(brand_row, delay, 0.8)
	await get_tree().create_timer(0.9).timeout
	JuicyScript.pulse_forever(easy_button, 1.04, 1.0)
	_bob_mascot()


func _bob_mascot() -> void:
	var base_y: float = mascot.position.y
	var tw: Tween = mascot.create_tween()
	tw.set_loops()
	tw.tween_property(mascot, "position:y", base_y - 12.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(mascot, "position:y", base_y, 0.7).set_trans(Tween.TRANS_SINE)


func _drift_clouds() -> void:
	for cloud in [cloud_a, cloud_b]:
		var base: Vector2 = cloud.position
		var tw: Tween = cloud.create_tween()
		tw.set_loops()
		tw.tween_property(cloud, "position:x", base.x + 36.0, 5.0).set_trans(Tween.TRANS_SINE)
		tw.tween_property(cloud, "position:x", base.x - 18.0, 5.0).set_trans(Tween.TRANS_SINE)


func _thump(btn: Control) -> void:
	btn.pivot_offset = btn.size * 0.5
	var tw: Tween = btn.create_tween()
	tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.06)
	tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.08)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.1)


func _start_mode(mode: String) -> void:
	GameState.set_mode(mode)
	GameState.start_level(1)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_easy_pressed() -> void:
	_thump(easy_button)
	await get_tree().create_timer(0.1).timeout
	_start_mode("easy")


func _on_hard_pressed() -> void:
	_thump(hard_button)
	await get_tree().create_timer(0.1).timeout
	_start_mode("hard")


func _on_crazy_pressed() -> void:
	_thump(crazy_button)
	await get_tree().create_timer(0.1).timeout
	_start_mode("crazy")


func _on_continue_pressed() -> void:
	_thump(continue_button)
	await get_tree().create_timer(0.1).timeout
	GameState.start_level(GameState.continue_level())
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_levels_pressed() -> void:
	_thump(levels_button)
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _on_premium_pressed() -> void:
	_thump(premium_button)
	Monetization.buy_full_game_unlock()
