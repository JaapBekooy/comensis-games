# Game Design Specification Document: SnoBird (Snokie-Inspired Mobile Precision Platformer)

---

## 1. Executive Summary & Overview

### 1.1 Project Concept
* **Game Title (Working):** *SnoBird: Frozen Path* (inspired by *Snokie* on Atari XL/800).
* **Target Engine:** Godot Engine 4.x (GDScript).
* **Target Platform:** Mobile (Android / iOS).
* **Genre:** 2D Single-Screen / Side-Scrolling Precision Platformer.
* **Core Philosophy:** Unforgiving, high-precision jumping with arcade-style timer mechanics, short re-try loops, and simple, responsive touchscreen controls.

### 1.2 Target Audience & Vibe
* **Vibe:** Retro 8-bit nostalgia with clean modern pixel crispness, bright icy aesthetics, and engaging arcade audio.
* **Audience:** Gamers who enjoy challenging platformers (e.g., *Super Meat Boy*, *Flappy Bird*, classic retro platformers) optimized for quick mobile play sessions.

---

## 2. Visual & Art Specifications

### 2.1 Resolution & Display Settings
* **Base Viewport Resolution:** $480 \times 270$ (Native 16:9 pixel-art aspect ratio).
* **Stretch Mode:** `canvas_items`
* **Aspect:** `keep`
* **Texture Filter:** `Nearest` (ensures sharp pixel art on modern Android mobile screens without blur).

### 2.2 Color Palette (Retro Ice Theme)
* **Ice/Snow:** Whites (`#F0F8FF`), Light Cyan (`#A0E0E0`), Deep Blue Ice (`#3B6998`).
* **SnoBird (Player):** Crisp Black (`#1A1A1A`), White Belly (`#FFFFFF`), Vibrant Orange Beak/Feet (`#FF8C00`), Red Scarf (`#E63946`).
* **Hazards/Boulders:** Slate Gray (`#4A5568`), Jagged Dark Gray (`#2D3748`).
* **Water/Gaps:** Deep Frozen Navy (`#0F172A`) with moving light cyan foam pixels.
* **Background:** Dark Blue Gradients (`#0B132B` to `#1C2541`) with subtle parallax scrolling snowy mountains.

### 2.3 Pixel Dimensions & Sprite Sheets
* **Player Sprite:** $16 \times 16$ pixels (Hitbox slightly smaller, approx. $12 \times 14$ px for forgiving hitboxes).
  * Animations: `idle` (2 frames), `walk` (4 frames), `jump_up` (1 frame), `fall` (1 frame), `hurt/death` (2 frames).
* **Tilemap Tiles:** $16 \times 16$ pixels.
  * Solid Ice Top, Ice Underground, Slippery Ice Surface, Hazard Water, Falling Stalactites, Moving Platforms (Ice Floes).
* **Boulders:** $16 \times 16$ pixels or $24 \times 24$ pixels (rotating sprite animation).

---

## 3. Core Gameplay & Physics Mechanics

### 3.1 Player Character (SnoBird) Physics Parameters
* **Base Gravity:** $980.0\ \text{px/s}^2$
* **Max Movement Speed:** $120.0\ \text{px/s}$
* **Acceleration:** $800.0\ \text{px/s}^2$
* **Friction / Ice Friction:**
  * Standard Ground Friction: $1200.0\ \text{px/s}^2$
  * Ice Surface Friction (Low Traction): $150.0\ \text{px/s}^2$ (gives slight momentum drift).
* **Jump Impulse:** $-280.0\ \text{px/s}$ (High vertical precision).
* **Coyote Time:** $0.08\text{s}$ (allows jumping shortly after walking off an edge).
* **Jump Buffer:** $0.1\text{s}$ (registers jump inputs made right before touching the ground).

### 3.2 Dynamic Hazards & Environmental Objects
1. **Rolling Boulders:**
   * Move laterally at fixed speeds ($60\text{--}100\ \text{px/s}$).
   * Bounce slightly off solid walls or fall down open gaps.
2. **Moving Ice Floes (Platforms):**
   * Move horizontally across water sections using `Path2D` or linear tweens.
   * Player moves synchronously when standing on top.
3. **Water / Deep Gaps:**
   * Trigger immediate player death (`Area2D` collision).
4. **Time Limit:**
   * Each level/screen has an active countdown timer (e.g., $30\text{--}45$ seconds). Running out of time results in immediate death.

### 3.3 Loop & Scoring System
* **Instant Retry:** Upon death, screen instantly restarts without loading delays.
* **Level Structure:** Linear sequence of distinct screens (Level 1 to Level 10). Reaching the rightmost edge of a level teleports SnoBird to the start of the next level.
* **Score Metrics:** Remaining Time converted to Bonus Points upon reaching the level finish flag.

---

## 4. Mobile User Interface & Touch Controls

### 4.1 On-Screen Touch Controls (HUD Overlay)
* **Left / Right Movement:** Virtual D-Pad buttons or discrete left/right arrow `TouchScreenButton` nodes positioned at the bottom-left corner of the screen.
* **Jump Button:** A large circular `TouchScreenButton` at the bottom-right corner.
* **Pause / Settings:** Gear icon in the top-right corner.

### 4.2 HUD Elements
* **Timer display:** Centered at top of screen (`Label` with pixel font).
* **Current Level display:** E.g., `LVL 01` (Top-Left corner).
* **Lives / Score Counter:** Top-Right corner.

---

## 5. Technical Architecture & Godot 4 Implementation Guide

*(Use this section specifically for prompting Cursor AI to generate code)*

### 5.1 Project Folder Structure
```text
res://
├── assets/
│   ├── sprites/       # SnoBird sheet, tilemap.png, hazards.png
│   ├── fonts/         # Pixel font (.ttf / .ttf)
│   └── audio/         # SFX (jump, die, win)
├── scenes/
│   ├── player/        # Player.tscn (CharacterBody2D)
│   ├── hazards/       # Boulder.tscn, WaterArea.tscn, IceFloe.tscn
│   ├── ui/            # TouchControls.tscn, HUD.tscn, MainMenu.tscn
│   └── levels/        # Level_01.tscn, Level_02.tscn, etc.
├── scripts/
│   ├── Player.gd
│   ├── GameManager.gd
│   └── Hazard.gd
└── default_bus_layout.tres
```

### 5.2 Core Script Interfaces & Godot Nodes

#### Player (`CharacterBody2D`) Node Setup:
```text
Player (CharacterBody2D)
├── Sprite2D (AnimationPlayer / AnimatedSprite2D)
├── CollisionShape2D (CapsuleShape2D / RectangleShape2D)
├── CoyoteTimer (Timer)
└── JumpBufferTimer (Timer)
```

#### Recommended Player Movement GDScript (`Player.gd` template for Cursor):
```gdscript
extends CharacterBody2D

signal player_died

@export var max_speed: float = 120.0
@export var acceleration: float = 800.0
@export var friction: float = 1200.0
@export var ice_friction: float = 150.0
@export var jump_velocity: float = -280.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_on_ice: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer

func _physics_process(delta: float) -> void:
	# Gravity handling
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Horizontal Movement handling
	var direction := Input.get_axis("ui_left", "ui_right")
	var current_friction = ice_friction if is_on_ice else friction
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
		sprite.flip_h = (direction < 0)
		sprite.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)
		sprite.play("idle")
		
	# Jumping mechanics
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or not coyote_timer.is_stopped()):
		velocity.y = jump_velocity
		
	move_and_slide()

func die() -> void:
	player_died.emit()
	queue_free()
```

---

## 6. Level Design Progression (Levels 1 - 3 Specification)

### Level 1: "The First Step" (Tutorial)
* **Objective:** Learn basic movement and jumping timing.
* **Layout:** Flat icy start platform $\rightarrow$ small $2$-tile gap over icy water $\rightarrow$ elevated platform $\rightarrow$ end goal flag.
* **Hazards:** Stationary water gap only.
* **Time Limit:** 30 Seconds.

### Level 2: "Rolling Danger"
* **Objective:** Dodge hazards while maintaining jump timing.
* **Layout:** Multi-tiered step layout. Boulders spawn periodically from top-left, rolling down steps towards the right.
* **Hazards:** 1 Rolling Boulder spawner ($2.5\text{s}$ interval), 2 medium water gaps.
* **Time Limit:** 35 Seconds.

### Level 3: "Unstable Ice Floes"
* **Objective:** Precision landing on moving objects.
* **Layout:** Wide water expanse separating two landmasses. 2 ice floe platforms move horizontally in opposing rhythms.
* **Hazards:** Water hazard across $60\%$ of the screen width, moving platforms.
* **Time Limit:** 40 Seconds.

---

## 7. Android Export & Deployment checklist for Cursor
1. **Android SDK & OpenJDK Configuration:** Ensure Godot editor settings point to standard Android SDK paths.
2. **Project Settings Checklist:**
   * Set display orientation to `Sensor Landscape` or `Landscape`.
   * Enable `Emulate Touch From Mouse` in `Input Devices / Pointing` for desktop testing.
   * Configure `TouchScreenButton` action mapping to standard UI input names (`ui_left`, `ui_right`, `ui_accept`).