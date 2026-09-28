class_name BoardView
extends Node2D
## Full-width board using beveled ice / brick tile textures.

const CELL: float = 128.0
const SLIDE_DURATION: float = 0.28

signal animation_finished

var logic: BoardLogic
var _floor_layer: Node2D
var _entity_layer: Node2D
var _fx_layer: Node2D
var _cube_nodes: Dictionary = {}
var _player_node: Node2D
var ice_material: ShaderMaterial

var _tex_floor0: Texture2D
var _tex_floor1: Texture2D
var _tex_wall: Texture2D
var _tex_target: Texture2D
var _tex_ice: Texture2D
var _tex_ice_hot: Texture2D
var _tex_player: Texture2D


func setup(board: BoardLogic, shader_mat: ShaderMaterial = null) -> void:
	logic = board
	ice_material = shader_mat
	_load_textures()
	for child in get_children():
		child.queue_free()
	_cube_nodes.clear()

	_floor_layer = Node2D.new()
	_entity_layer = Node2D.new()
	_fx_layer = Node2D.new()
	add_child(_floor_layer)
	add_child(_entity_layer)
	add_child(_fx_layer)

	_rebuild_static()
	rebuild_entities()
	_pop_in_board()
	if not logic.state_changed.is_connected(_on_state_changed):
		logic.state_changed.connect(_on_state_changed)
	if not logic.cube_slid.is_connected(_on_cube_slid):
		logic.cube_slid.connect(_on_cube_slid)
	if not logic.player_moved.is_connected(_on_player_moved):
		logic.player_moved.connect(_on_player_moved)


func _load_textures() -> void:
	_tex_floor0 = load("res://assets/tiles/floor_0.png") as Texture2D
	_tex_floor1 = load("res://assets/tiles/floor_1.png") as Texture2D
	_tex_wall = load("res://assets/tiles/wall.png") as Texture2D
	_tex_target = load("res://assets/tiles/target.png") as Texture2D
	_tex_ice = load("res://assets/tiles/ice_cube.png") as Texture2D
	_tex_ice_hot = load("res://assets/tiles/ice_cube_hot.png") as Texture2D
	_tex_player = load("res://assets/tiles/player.png") as Texture2D


func grid_pixel_size() -> Vector2:
	return Vector2(logic.grid_size) * CELL


func grid_to_pixel(pos: Vector2i) -> Vector2:
	return Vector2(pos) * CELL + Vector2(CELL, CELL) * 0.5


func _sprite(tex: Texture2D) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = true
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	## Scale 128px art to CELL if needed
	if tex:
		var sz: Vector2 = tex.get_size()
		if sz.x > 0.0:
			s.scale = Vector2(CELL / sz.x, CELL / sz.y)
	return s


func _pop_in_board() -> void:
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.2)


func _rebuild_static() -> void:
	for child in _floor_layer.get_children():
		child.queue_free()
	for y in range(logic.grid_size.y):
		for x in range(logic.grid_size.x):
			var pos := Vector2i(x, y)
			var tile: int = logic.get_floor(pos)
			var root := Node2D.new()
			root.position = grid_to_pixel(pos)
			match tile:
				BoardLogic.TILE_WALL:
					root.add_child(_sprite(_tex_wall))
				BoardLogic.TILE_TARGET:
					root.add_child(_sprite(_tex_target))
				_:
					var alt: bool = ((x + y) % 2) == 0
					root.add_child(_sprite(_tex_floor0 if alt else _tex_floor1))
			_floor_layer.add_child(root)


func rebuild_entities() -> void:
	for child in _entity_layer.get_children():
		child.queue_free()
	_cube_nodes.clear()

	for cube_pos in logic.cube_positions:
		var cube := _make_cube(cube_pos)
		cube.position = grid_to_pixel(cube_pos)
		_entity_layer.add_child(cube)
		_cube_nodes[cube_pos] = cube

	_player_node = _make_player()
	_player_node.position = grid_to_pixel(logic.player_pos)
	_entity_layer.add_child(_player_node)


func _make_cube(at: Vector2i) -> Node2D:
	var root := Node2D.new()
	var on_target: bool = logic.get_floor(at) == BoardLogic.TILE_TARGET
	var spr := _sprite(_tex_ice_hot if on_target else _tex_ice)
	if ice_material and not on_target:
		spr.material = ice_material
	root.add_child(spr)
	return root


func _make_player() -> Node2D:
	var root := Node2D.new()
	root.add_child(_sprite(_tex_player))
	return root


func _on_state_changed() -> void:
	if logic.is_animating:
		return
	_sync_cube_keys()


func _sync_cube_keys() -> void:
	if _cube_nodes.size() != logic.cube_positions.size():
		rebuild_entities()
		return
	for pos in logic.cube_positions:
		if not _cube_nodes.has(pos):
			rebuild_entities()
			return
	if _player_node:
		_player_node.position = grid_to_pixel(logic.player_pos)


func _on_player_moved(from_pos: Vector2i, to_pos: Vector2i) -> void:
	if _player_node == null:
		return
	Juicy.squash_stretch(_player_node, to_pos - from_pos)
	var tween: Tween = create_tween()
	tween.tween_property(_player_node, "position", grid_to_pixel(to_pos), 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_cube_slid(from_pos: Vector2i, to_pos: Vector2i) -> void:
	logic.is_animating = true
	var node: Node2D = _cube_nodes.get(from_pos) as Node2D
	if node == null:
		rebuild_entities()
		logic.is_animating = false
		animation_finished.emit()
		return

	_cube_nodes.erase(from_pos)
	_cube_nodes[to_pos] = node
	AudioManager.play_slide()
	var dir: Vector2i = to_pos - from_pos
	Juicy.squash_stretch(node, dir)

	var dist: float = Vector2(dir).length()
	var duration: float = clampf(SLIDE_DURATION + dist * 0.04, 0.2, 0.55)
	var tween: Tween = create_tween()
	tween.tween_property(node, "position", grid_to_pixel(to_pos), duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		AudioManager.play_crunch()
		Juicy.punch(node, 1.2)
		_refresh_cube_texture(node, to_pos)
		_spawn_burst(grid_to_pixel(to_pos))
		logic.is_animating = false
		animation_finished.emit()
	)


func _refresh_cube_texture(node: Node2D, at: Vector2i) -> void:
	if node.get_child_count() == 0:
		return
	var spr := node.get_child(0) as Sprite2D
	if spr == null:
		return
	var on_target: bool = logic.get_floor(at) == BoardLogic.TILE_TARGET
	spr.texture = _tex_ice_hot if on_target else _tex_ice


func play_win_fx() -> void:
	for cube_pos in logic.cube_positions:
		var n: Node2D = _cube_nodes.get(cube_pos) as Node2D
		if n:
			Juicy.punch(n, 1.35)
			_spawn_burst(grid_to_pixel(cube_pos))
	if _player_node:
		Juicy.punch(_player_node, 1.3)


func _spawn_burst(at_pos: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 24
	particles.lifetime = 0.5
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 140)
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 7.0
	particles.color = Color(0.7, 0.9, 1.0, 1.0)
	particles.position = at_pos
	_fx_layer.add_child(particles)
	get_tree().create_timer(0.65).timeout.connect(particles.queue_free)
