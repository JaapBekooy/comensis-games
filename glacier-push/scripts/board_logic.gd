class_name BoardLogic
extends RefCounted
## Grid puzzle logic: player steps one cell; ice cubes slide until blocked.

const TILE_EMPTY: int = 0
const TILE_WALL: int = 1
const TILE_ICE_CUBE: int = 2
const TILE_TARGET: int = 3
const TILE_PLAYER: int = 4

signal state_changed
signal cube_slid(from_pos: Vector2i, to_pos: Vector2i)
signal player_moved(from_pos: Vector2i, to_pos: Vector2i)
signal level_won

var grid_size: Vector2i = Vector2i(8, 10)
## Static floor: EMPTY / WALL / TARGET only.
var floor_grid: Array = []
var cube_positions: Array[Vector2i] = []
var player_pos: Vector2i = Vector2i.ZERO
var history_stack: Array = []
var is_won: bool = false
var is_animating: bool = false


func load_from_dict(data: Dictionary) -> void:
	grid_size = Vector2i(int(data.get("width", 8)), int(data.get("height", 10)))
	floor_grid.clear()
	cube_positions.clear()
	history_stack.clear()
	is_won = false
	is_animating = false

	var rows: Array = data.get("grid", [])
	for y in range(grid_size.y):
		var row: Array = []
		var src: Array = rows[y] if y < rows.size() else []
		for x in range(grid_size.x):
			var cell: int = int(src[x]) if x < src.size() else TILE_EMPTY
			match cell:
				TILE_ICE_CUBE:
					row.append(TILE_EMPTY)
					cube_positions.append(Vector2i(x, y))
				TILE_PLAYER:
					row.append(TILE_EMPTY)
					player_pos = Vector2i(x, y)
				TILE_TARGET:
					row.append(TILE_TARGET)
				TILE_WALL:
					row.append(TILE_WALL)
				_:
					row.append(TILE_EMPTY)
		floor_grid.append(row)

	## Optional explicit cube list (preserves targets underneath).
	if data.has("cubes"):
		cube_positions.clear()
		var cubes_data: Array = data["cubes"]
		for item in cubes_data:
			var c: Array = item
			cube_positions.append(Vector2i(int(c[0]), int(c[1])))

	if data.has("player"):
		var p: Array = data["player"]
		player_pos = Vector2i(int(p[0]), int(p[1]))

	state_changed.emit()


func get_floor(pos: Vector2i) -> int:
	if not _in_bounds(pos):
		return TILE_WALL
	return int(floor_grid[pos.y][pos.x])


func has_cube(pos: Vector2i) -> bool:
	return cube_positions.has(pos)


func try_move(dir: Vector2i) -> bool:
	if is_won or is_animating or dir == Vector2i.ZERO:
		return false

	var next: Vector2i = player_pos + dir
	if not _is_walkable_for_player(next):
		return false

	if has_cube(next):
		var end_pos: Vector2i = _slide_end(next, dir)
		if end_pos == next:
			return false
		_save_history()
		var from_cube: Vector2i = next
		_move_cube(from_cube, end_pos)
		var from_player: Vector2i = player_pos
		player_pos = next
		player_moved.emit(from_player, player_pos)
		cube_slid.emit(from_cube, end_pos)
		state_changed.emit()
		_check_win()
		return true

	_save_history()
	var from_p: Vector2i = player_pos
	player_pos = next
	player_moved.emit(from_p, player_pos)
	state_changed.emit()
	return true


func undo() -> bool:
	if history_stack.is_empty() or is_animating or is_won:
		return false
	var snap: Dictionary = history_stack.pop_back()
	player_pos = snap["player"]
	cube_positions = snap["cubes"].duplicate()
	is_won = false
	state_changed.emit()
	return true


func reset_to(data: Dictionary) -> void:
	load_from_dict(data)


func _slide_end(start: Vector2i, dir: Vector2i) -> Vector2i:
	var current: Vector2i = start
	var next: Vector2i = current + dir
	while _is_passable_for_cube(next):
		current = next
		next = current + dir
	return current


func _is_passable_for_cube(pos: Vector2i) -> bool:
	if not _in_bounds(pos):
		return false
	if get_floor(pos) == TILE_WALL:
		return false
	if has_cube(pos):
		return false
	if pos == player_pos:
		return false
	return true


func _is_walkable_for_player(pos: Vector2i) -> bool:
	if not _in_bounds(pos):
		return false
	return get_floor(pos) != TILE_WALL


func _move_cube(from_pos: Vector2i, to_pos: Vector2i) -> void:
	var idx: int = cube_positions.find(from_pos)
	if idx >= 0:
		cube_positions[idx] = to_pos


func _save_history() -> void:
	history_stack.append({
		"player": player_pos,
		"cubes": cube_positions.duplicate(),
	})


func _check_win() -> void:
	for cube in cube_positions:
		if get_floor(cube) != TILE_TARGET:
			return
	if cube_positions.is_empty():
		return
	is_won = true
	level_won.emit()


func _in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y


func count_targets() -> int:
	var n: int = 0
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			if int(floor_grid[y][x]) == TILE_TARGET:
				n += 1
	return n


func cubes_on_targets() -> int:
	var n: int = 0
	for cube in cube_positions:
		if get_floor(cube) == TILE_TARGET:
			n += 1
	return n
