# Glacier Push

Colorful ice-sliding Sokoban by **Comensis**. Built for **Godot 4.7**.

## Phases 1–4 (done)

1. **Bootstrap** — `project.godot` (1080×1920, stretch expand), autoloads, `.cursorrules`
2. **Core loop** — slide ice, undo, win, keyboard + swipe
3. **Content** — 250 BFS-verified levels (rising difficulty), menus, save progress, SFX/music
4. **Polish** — Candy-Crush-like juicy UI, bounce/pop animations, ice shader, particles, safe margins

## Open & play (Mac)

1. Install [Godot 4.7+](https://godotengine.org/download)
2. **Import** this folder
3. Press **F5**

## Controls

- Arrows / WASD or swipe — move  
- Z / U — undo · R — restart  

## Modes

- **Easy** — 50 levels · 2 ice blocks  
- **Hard** — 50 levels · 3–4 ice blocks  
- **Crazy** — 50 levels · 5–6 ice blocks  

All levels are solver-checked. Regenerate with:

```bash
python3 tools/generate_levels.py
```

## Later (not in Phases 1–4)

- Android export / device QA  
- Real AdMob + Play Billing (desktop stub already in `Monetization`)
