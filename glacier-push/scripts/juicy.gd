class_name Juicy
extends RefCounted
## Shared Candy-Crush-like colors, rounded styles, and bounce helpers.


static func palette() -> Dictionary:
	return {
		"sky_top": Color("7ED6FF"),
		"sky_bot": Color("FF9ECD"),
		"hill": Color("7CFFB2"),
		"title": Color("FFE566"),
		"title_outline": Color("C44D1A"),
		"play": Color("FF5FA8"),
		"play_shadow": Color("D63A7F"),
		"continue": Color("4DB7FF"),
		"continue_shadow": Color("2B7FCC"),
		"secondary": Color("B57CFF"),
		"premium": Color("FFB347"),
		"floor": Color("E8F9FF"),
		"floor_alt": Color("D4F2FF"),
		"wall": Color("6B8CFF"),
		"wall_top": Color("9BB0FF"),
		"target": Color("FFF06A"),
		"target_ring": Color("FF8C42"),
		"ice": Color("A8F0FF"),
		"ice_edge": Color("5BC8E8"),
		"bear": Color("FFF8F0"),
		"bear_blush": Color("FF9EBB"),
		"text_dark": Color("3A2A5C"),
		"text_light": Color("FFFFFF"),
		"win": Color("FF6BCB"),
	}


static func round_style(
	bg: Color,
	radius: float = 28.0,
	border: float = 4.0,
	border_color: Color = Color(1, 1, 1, 0.55),
	shadow_size: int = 8,
	shadow_color: Color = Color(0, 0, 0, 0.18),
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(int(radius))
	sb.set_border_width_all(int(border))
	sb.border_color = border_color
	sb.shadow_size = shadow_size
	sb.shadow_color = shadow_color
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 14
	return sb


static func style_button(btn: Button, bg: Color, font_size: int = 36) -> void:
	var normal := round_style(bg, 40.0, 5.0, bg.lightened(0.35), 10, Color(0, 0, 0, 0.22))
	var hover := round_style(bg.lightened(0.08), 40.0, 5.0, Color(1, 1, 1, 0.7), 12, Color(0, 0, 0, 0.2))
	var pressed := round_style(bg.darkened(0.08), 40.0, 5.0, bg.lightened(0.2), 4, Color(0, 0, 0, 0.25))
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", round_style(bg.darkened(0.25), 40.0, 4.0, Color(1, 1, 1, 0.2), 0))
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.92))
	btn.add_theme_font_size_override("font_size", font_size)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


static func bounce_in(node: CanvasItem, delay: float = 0.0, from_scale: float = 0.6) -> void:
	if node is Control:
		var c := node as Control
		c.pivot_offset = c.size * 0.5
	node.scale = Vector2(from_scale, from_scale)
	node.modulate.a = 0.0
	var tw: Tween = node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "modulate:a", 1.0, 0.35).set_delay(delay)
	tw.tween_property(node, "scale", Vector2.ONE, 0.55)\
		.set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func pulse_forever(node: CanvasItem, amount: float = 1.04, period: float = 1.2) -> void:
	if node is Control:
		var c := node as Control
		c.pivot_offset = c.size * 0.5
	var tw: Tween = node.create_tween()
	tw.set_loops()
	tw.tween_property(node, "scale", Vector2(amount, amount), period)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, period)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


static func punch(node: Node2D, peak: float = 1.25) -> void:
	var tw: Tween = node.create_tween()
	tw.tween_property(node, "scale", Vector2(peak, peak), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2(0.9, 1.1), 0.08)
	tw.tween_property(node, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func squash_stretch(node: Node2D, dir: Vector2i) -> void:
	var stretch: Vector2 = Vector2(1.25, 0.75) if abs(dir.x) > abs(dir.y) else Vector2(0.75, 1.25)
	var tw: Tween = node.create_tween()
	tw.tween_property(node, "scale", stretch, 0.06)
	tw.tween_property(node, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func make_round_panel(size: Vector2, color: Color, radius: float = 22.0) -> Panel:
	var panel := Panel.new()
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var edge := color.darkened(0.12)
	panel.add_theme_stylebox_override(
		"panel",
		round_style(color, radius, 4.0, color.lightened(0.35), 6, Color(0, 0, 0, 0.12)),
	)
	# silence unused
	edge = edge
	return panel
