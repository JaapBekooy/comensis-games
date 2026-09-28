# Ice Sliding Puzzle Game — Technical Specification & Architecture Document

## 1. Project Summary & Goals
- **Game Genre:** Grid-based Sokoban/Boxxle-style puzzle game with continuous ice-sliding mechanics.
- **Target Platform:** Android (optimized for all form factors: phones, 16:9 to 21:9 devices, and tablets/foldables).
- **Development Toolchain:** 100% Free Tools (Godot 4.x, Cursor Free Tier, Kenney.nl assets).
- **Monetization Architecture:**
  - Standard User: Non-intrusive AdMob Interstitials (1 ad every 3 levels) + Rewarded Ads for optional hints.
  - Premium Tier: Single $1.99 USD / €1.99 Non-Consumable In-App Purchase ("Remove Ads / Unlock Full Game").

---

## 2. Free Toolchain & Setup

| Domain | Tool | Description / Role |
| :--- | :--- | :--- |
| **Game Engine** | **Godot 4.x** | Open-source, lightweight, native GDScript support, zero licensing fees. |
| **Code Editor** | **Cursor** | AI-assisted coding environment reading/writing GDScript natively. |
| **Asset Pipeline** | **Kenney.nl (CC0)** | Free public domain textures, UI icons, and audio samples. |
| **Ads & IAP** | **Godot AdMob & Play Billing Plugins** | Official Android monetization plugins. |

### Cursor Integration (`.cursorrules`)
Place a `.cursorrules` file in the project root folder to ensure Cursor AI outputs Godot 4-compliant GDScript:

```text
# Godot 4.x Rules for Cursor AI
- Always use Godot 4.x syntax (e.g., `await` instead of `yield`, `@export` instead of `export`).
- Keep code strictly typed (e.g., `var position: Vector2i`).
- Prefer Signal-driven architecture over polling in _process().
- Organize grid logic using Vector2i dictionaries or 2D Arrays.
```

---

## 3. Screen Scaling & Display Configuration

To support all dynamic aspect ratios smoothly without distortion or letterboxing:

1. **Base Viewport:** Set resolution to `1080 x 1920` (Portrait mode).
2. **Stretch Mode:** Set to `canvas_items`.
3. **Stretch Aspect:** Set to `expand`.
4. **UI Safe Zones:** Anchor puzzle grids within a centered `MarginContainer` to account for camera cutouts and notch margins.

---

## 4. Core Game Mechanics & Logic Blueprint

### Cell Types Definition
- `0: EMPTY` - Regular floor space.
- `1: WALL` - Solid collision barrier.
- `2: ICE_CUBE` - Pushable obstacle sliding until hitting a solid cell.
- `3: TARGET` - Drop zone required for level completion.

### Sliding Algorithm & Undo Stack Implementation

```gdscript
extends Node2D

const TILE_EMPTY: int = 0
const TILE_WALL: int = 1
const TILE_ICE_CUBE: int = 2
const TILE_TARGET: int = 3

@export var grid_size: Vector2i = Vector2i(8, 10)
var history_stack: Array[Array] = [] # Stores previous grid array states

func push_cube(cube_pos: Vector2i, dir: Vector2i) -> void:
	var current_pos: Vector2i = cube_pos
	var next_pos: Vector2i = current_pos + dir
	
	# Slide continuously until an obstacle/wall is hit
	while is_passable(next_pos):
		current_pos = next_pos
		next_pos = current_pos + dir
		
	if current_pos != cube_pos:
		save_state_to_history()
		animate_cube_slide(cube_pos, current_pos)

func is_passable(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= grid_size.x or pos.y < 0 or pos.y >= grid_size.y:
		return false
	var cell_type: int = get_cell_type(pos)
	return cell_type != TILE_WALL and cell_type != TILE_ICE_CUBE

func save_state_to_history() -> void:
	# Deep copy current board state into history stack
	history_stack.append(get_current_board_state().duplicate(true))

func undo_last_move() -> void:
	if history_stack.size() > 0:
		var last_state: Array = history_stack.pop_back()
		restore_board_state(last_state)

func animate_cube_slide(from_pos: Vector2i, to_pos: Vector2i) -> void:
	var cube_sprite = get_cube_node_at(from_pos)
	var target_pixel_pos = grid_to_pixel(to_pos)
	
	var tween = create_tween()
	tween.tween_property(cube_sprite, "position", target_pixel_pos, 0.22)\
		 .set_trans(Tween.TRANS_QUAD)\
		 .set_ease(Tween.EASE_OUT)
```

---

## 5. Monetization Strategy & Policy Compliance

### Google AdMob Policy Compliance
- **Policy Rule:** Do not serve consecutive or intrusive full-screen ads. High ad frequency triggers invalid click flags and degrades retention.
- **Implementation Strategy:**
  - **Levels 1 to 5:** Free play, 0 forced ads (smooth onboarding).
  - **Level 6+:** Trigger 1 interstitial ad every **3 level clears**.
  - **Optional Hints:** Rewarded Video Ads grants 1 hint on demand.

### In-App Purchase Flow ($1.99 / €1.99 Non-Consumable)

```gdscript
extends Node

var is_premium: bool = false
var levels_completed: int = 0

func _ready() -> void:
	check_purchased_products()

func on_level_complete() -> void:
	levels_completed += 1
	
	if not is_premium and levels_completed % 3 == 0:
		show_interstitial_ad()

func buy_full_game_unlock() -> void:
	# Call Godot Play Billing plugin API
	GooglePlayBilling.purchase("unlock_full_game_199")

func _on_purchase_success(product_id: String) -> void:
	if product_id == "unlock_full_game_199":
		is_premium = true
		save_premium_status(true)
		hide_all_banner_ads()
```

---

## 6. Visuals & Audio Polish Checklist

1. **Ice Shader:** Apply a subtle glass/refraction shader on the ice blocks.
2. **Particle Systems:** Emit frost/dust particle bursts when an ice cube hits a wall.
3. **Audio Cues:**
   - Soft sliding audio loop during block movement.
   - Distinct "crunch/clack" sound on collision.
   - High-pitched chime on solving the grid.