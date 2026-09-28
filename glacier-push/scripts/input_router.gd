class_name InputRouter
extends Node
## Keyboard (Mac) + swipe (touch / Android).

signal move_requested(dir: Vector2i)
signal undo_requested
signal restart_requested

const SWIPE_THRESHOLD: float = 48.0

var _touch_start: Vector2 = Vector2.ZERO
var _touching: bool = false
var enabled: bool = true


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return

	if event.is_action_pressed("move_up"):
		move_requested.emit(Vector2i(0, -1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		move_requested.emit(Vector2i(0, 1))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_left"):
		move_requested.emit(Vector2i(-1, 0))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("move_right"):
		move_requested.emit(Vector2i(1, 0))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("undo"):
		undo_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart"):
		restart_requested.emit()
		get_viewport().set_input_as_handled()

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_touching = true
			_touch_start = touch.position
		elif _touching:
			_touching = false
			_emit_swipe(touch.position - _touch_start)
			get_viewport().set_input_as_handled()

	if event is InputEventScreenDrag:
		pass


func _emit_swipe(delta: Vector2) -> void:
	if delta.length() < SWIPE_THRESHOLD:
		return
	if absf(delta.x) > absf(delta.y):
		move_requested.emit(Vector2i(1 if delta.x > 0.0 else -1, 0))
	else:
		move_requested.emit(Vector2i(0, 1 if delta.y > 0.0 else -1))
