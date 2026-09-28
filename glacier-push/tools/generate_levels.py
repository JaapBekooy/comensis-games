#!/usr/bin/env python3
"""Regenerate Easy / Hard / Crazy with denser obstacles (order matters).

Crazy especially: maze walls, narrow corridors, cubes that block each other.
All levels BFS-verified solvable. 50 per mode.
"""

from __future__ import annotations

import json
import random
import time
from collections import deque
from pathlib import Path

EMPTY, WALL, TARGET = 0, 1, 3
ROOT = Path(__file__).resolve().parents[1] / "levels"
DIRS = [(1, 0), (-1, 0), (0, 1), (0, -1)]
PER_MODE = 50


def border(w, h):
    s = set()
    for x in range(w):
        s.add((x, 0))
        s.add((x, h - 1))
    for y in range(h):
        s.add((0, y))
        s.add((w - 1, y))
    return s


def inb(x, y, w, h):
    return 0 <= x < w and 0 <= y < h


def slide_end(sx, sy, dx, dy, w, h, walls, others):
    cx, cy = sx, sy
    while True:
        nx, ny = cx + dx, cy + dy
        if not inb(nx, ny, w, h) or (nx, ny) in walls or (nx, ny) in others:
            break
        cx, cy = nx, ny
    return cx, cy


def solve(w, h, walls, targets, player, cubes, max_depth=100, max_states=350_000):
    targets = frozenset(targets)
    cubes = frozenset(cubes)
    if cubes == targets:
        return 0
    q = deque([(player, cubes, 0)])
    seen = {(player, cubes)}
    while q:
        (px, py), cur, dist = q.popleft()
        if dist >= max_depth:
            continue
        for dx, dy in DIRS:
            nx, ny = px + dx, py + dy
            if not inb(nx, ny, w, h) or (nx, ny) in walls:
                continue
            if (nx, ny) in cur:
                others = set(cur)
                others.remove((nx, ny))
                end = slide_end(nx, ny, dx, dy, w, h, walls, others)
                if end == (nx, ny):
                    continue
                nc = frozenset(others | {end})
                np = (nx, ny)
            else:
                nc, np = cur, (nx, ny)
            st = (np, nc)
            if st in seen:
                continue
            if nc == targets:
                return dist + 1
            seen.add(st)
            if len(seen) > max_states:
                return None
            q.append((np, nc, dist + 1))
    return None


def has_push_runway(tx, ty, walls, w, h, min_len=2):
    """True if cube on (tx,ty) can be reverse-pushed: stop + runway + stand cell."""
    for dx, dy in DIRS:
        nx, ny = tx + dx, ty + dy
        blocked = not inb(nx, ny, w, h) or (nx, ny) in walls
        if not blocked:
            continue
        # need min_len open cells opposite the stop, plus a stand cell beyond
        ok = True
        for i in range(1, min_len + 2):
            cx, cy = tx - dx * i, ty - dy * i
            if not inb(cx, cy, w, h) or (cx, cy) in walls:
                ok = False
                break
        if ok:
            return True
    return False


def carve_maze(rng, w, h, density: float):
    """Dense chambers linked by 1-wide corridors — forces cube order."""
    walls = border(w, h)
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            walls.add((x, y))

    # Rooms big enough for a push runway (2x3), spaced so corridors stay narrow
    stride_x = 4 if w >= 10 else 3
    stride_y = 4 if h >= 10 else 3
    room_w = 3 if w >= 10 else 2
    room_h = 2
    rooms = []
    y = 1
    while y + room_h <= h - 1:
        x = 1
        while x + room_w <= w - 1:
            rooms.append((x, y, room_w, room_h))
            for yy in range(y, y + room_h):
                for xx in range(x, x + room_w):
                    walls.discard((xx, yy))
            x += stride_x
        y += stride_y

    if not rooms:
        for yy in range(2, h - 2):
            for xx in range(2, w - 2):
                walls.discard((xx, yy))
        rooms = [(2, 2, max(2, w - 4), max(2, h - 4))]

    # Connect rooms with single-tile L corridors (bottlenecks)
    order = list(range(len(rooms)))
    rng.shuffle(order)
    for i in range(1, len(order)):
        ax, ay, aw, ah = rooms[order[i - 1]]
        bx, by, bw, bh = rooms[order[i]]
        acx, acy = ax + aw // 2, ay + ah // 2
        bcx, bcy = bx + bw // 2, by + bh // 2
        x, y = acx, acy
        if rng.random() < 0.5:
            while x != bcx:
                walls.discard((x, y))
                x += 1 if bcx > x else -1
            while y != bcy:
                walls.discard((x, y))
                y += 1 if bcy > y else -1
        else:
            while y != bcy:
                walls.discard((x, y))
                y += 1 if bcy > y else -1
            while x != bcx:
                walls.discard((x, y))
                x += 1 if bcx > x else -1

    # Ring link so the graph isn't a pure tree
    if len(rooms) > 2:
        ax, ay, aw, ah = rooms[order[0]]
        bx, by, bw, bh = rooms[order[-1]]
        acx, acy = ax + aw // 2, ay + ah // 2
        bcx, bcy = bx + bw // 2, by + bh // 2
        x, y = acx, acy
        while x != bcx:
            walls.discard((x, y))
            x += 1 if bcx > x else -1
        while y != bcy:
            walls.discard((x, y))
            y += 1 if bcy > y else -1

    # Side pockets with a 3-cell runway (target + slide + stand)
    free_now = [
        (x, y) for y in range(1, h - 1) for x in range(1, w - 1) if (x, y) not in walls
    ]
    rng.shuffle(free_now)
    pockets = max(3, len(rooms) // 2)
    for fx, fy in free_now:
        if pockets <= 0:
            break
        for dx, dy in DIRS:
            cells = [(fx + dx * i, fy + dy * i) for i in range(1, 4)]
            if not all(
                inb(cx, cy, w, h) and 0 < cx < w - 1 and 0 < cy < h - 1
                for cx, cy in cells
            ):
                continue
            if not all(c in walls for c in cells):
                continue
            for c in cells:
                walls.discard(c)
            pockets -= 1
            break

    interior_n = (w - 2) * (h - 2)
    wall_n = sum(
        1 for yy in range(1, h - 1) for xx in range(1, w - 1) if (xx, yy) in walls
    )
    target_walls = int(interior_n * density)
    cells = [(x, y) for y in range(1, h - 1) for x in range(1, w - 1)]
    rng.shuffle(cells)
    if wall_n > target_walls + 2:
        for c in cells:
            if wall_n <= target_walls:
                break
            if c in walls:
                open_n = sum(
                    1 for dx, dy in DIRS if (c[0] + dx, c[1] + dy) not in walls
                )
                if open_n <= 1:
                    walls.discard(c)
                    wall_n -= 1
    elif wall_n < target_walls:
        for c in cells:
            if wall_n >= target_walls:
                break
            if c not in walls:
                open_n = sum(
                    1 for dx, dy in DIRS if (c[0] + dx, c[1] + dy) not in walls
                )
                if open_n >= 3:
                    walls.add(c)
                    wall_n += 1

    return walls, rooms


def place_targets_in_pockets(rng, w, h, walls, n, rooms):
    """Targets against a stop with a push runway so scramble can unpush."""
    free = [
        (x, y)
        for y in range(1, h - 1)
        for x in range(1, w - 1)
        if (x, y) not in walls
    ]
    runnable = [c for c in free if has_push_runway(c[0], c[1], walls, w, h, 2)]
    # Prefer tighter pockets among runnable cells
    scored = []
    for c in runnable:
        nwalls = sum(
            1
            for dx, dy in DIRS
            if (c[0] + dx, c[1] + dy) in walls
            or not inb(c[0] + dx, c[1] + dy, w, h)
        )
        scored.append((nwalls, c))
    scored.sort(key=lambda t: -t[0])
    ordered = [c for _, c in scored]
    if len(ordered) < n:
        # last resort: any free cell with at least a 1-step runway
        ordered = [c for c in free if has_push_runway(c[0], c[1], walls, w, h, 1)]
        rng.shuffle(ordered)
    if len(ordered) < n:
        return None
    picks = []
    for c in ordered:
        if all(abs(c[0] - p[0]) + abs(c[1] - p[1]) >= 2 for p in picks):
            picks.append(c)
        if len(picks) == n:
            break
    if len(picks) < n:
        for c in ordered:
            if c not in picks:
                picks.append(c)
            if len(picks) == n:
                break
    return set(picks[:n])


def reverse_push(rng, level):
    """Unpush one cube. Player stands on the push approach cell (solvable)."""
    w, h = level["w"], level["h"]
    walls = level["walls"]
    cubes = set(level["cubes"])
    cl = list(cubes)
    rng.shuffle(cl)
    dirs = list(DIRS)
    rng.shuffle(dirs)
    candidates = []
    for cx, cy in cl:
        for dx, dy in dirs:
            nx, ny = cx + dx, cy + dy
            blocked = (
                not inb(nx, ny, w, h)
                or (nx, ny) in walls
                or (nx, ny) in (cubes - {(cx, cy)})
            )
            if not blocked:
                continue
            ox, oy = cx - dx, cy - dy
            while inb(ox, oy, w, h):
                if (ox, oy) in walls or (ox, oy) in cubes:
                    break
                end = slide_end(ox, oy, dx, dy, w, h, walls, cubes - {(cx, cy)})
                if end == (cx, cy):
                    stand = (ox - dx, oy - dy)
                    if (
                        inb(stand[0], stand[1], w, h)
                        and stand not in walls
                        and stand not in cubes
                        and stand != (ox, oy)
                    ):
                        dist = abs(ox - cx) + abs(oy - cy)
                        candidates.append((dist, (cx, cy), (ox, oy), stand))
                ox -= dx
                oy -= dy
    if not candidates:
        return None
    candidates.sort(key=lambda t: -t[0])
    pool = candidates[: min(6, len(candidates))]
    _dist, rest, pick, stand = pool[0] if rng.random() < 0.65 else rng.choice(pool)
    new_cubes = set(cubes)
    new_cubes.remove(rest)
    new_cubes.add(pick)
    if stand in new_cubes:
        return None
    out = dict(level)
    out["cubes"] = new_cubes
    out["player"] = stand
    return out


def scramble(rng, level, steps: int):
    cur = level
    applied = 0
    for _ in range(steps * 16):
        if applied >= steps:
            break
        nxt = reverse_push(rng, cur)
        if nxt is None:
            continue
        cur = nxt
        applied += 1
    return cur, applied


def wall_density(level) -> float:
    w, h = level["w"], level["h"]
    interior = (w - 2) * (h - 2)
    if interior <= 0:
        return 0.0
    walls = sum(1 for x, y in level["walls"] if 0 < x < w - 1 and 0 < y < h - 1)
    return walls / interior


def build_maze_level(rng, w, h, n_cubes, density: float, rev: int):
    walls, rooms = carve_maze(rng, w, h, density)
    if len(rooms) < 1:
        return None
    targets = place_targets_in_pockets(rng, w, h, walls, n_cubes, rooms)
    if targets is None or len(targets) < n_cubes:
        return None
    free = [
        (x, y)
        for y in range(1, h - 1)
        for x in range(1, w - 1)
        if (x, y) not in walls and (x, y) not in targets
    ]
    if len(free) < 1:
        return None
    rng.shuffle(free)
    cubes = set(targets)
    player = free[0]
    level = {
        "w": w,
        "h": h,
        "walls": walls,
        "targets": frozenset(targets),
        "cubes": cubes,
        "player": player,
    }
    scrambled, applied = scramble(rng, level, rev)
    if applied < max(2, rev // 3):
        scrambled, applied = scramble(rng, level, rev + 6)
    if len(scrambled["cubes"]) != n_cubes:
        return None
    on_tgt = sum(1 for c in scrambled["cubes"] if c in scrambled["targets"])
    if on_tgt == n_cubes:
        return None
    # Prefer mostly off-target; allow 1 parked on target for dense boards
    if on_tgt > max(1, n_cubes // 3) and applied < rev // 2:
        return None
    scrambled["applied"] = applied
    return scrambled


def mode_spec(mode: str, index: int) -> dict:
    t = index / max(PER_MODE - 1, 1)
    if mode == "easy":
        return {
            "w": 8,
            "h": 8,
            "cubes": 2 if t < 0.55 else 3,
            "density": 0.32 + t * 0.10,
            "rev": 5 + int(t * 5),
            "min_moves": 3,
            "depth": 45,
        }
    if mode == "hard":
        return {
            "w": 9 + int(t * 1),
            "h": 9 + int(t * 1),
            "cubes": 3 if t < 0.35 else 4,
            "density": 0.42 + t * 0.12,
            "rev": 10 + int(t * 8),
            "min_moves": 8,
            "depth": 75,
        }
    # crazy — dense maze, 5–6 cubes, order matters
    return {
        "w": 11 + int(t * 1),
        "h": 10 + int(t * 2),
        "cubes": 5 if t < 0.4 else 6,
        "density": 0.50 + t * 0.12,
        "rev": 12 + int(t * 10),
        "min_moves": 10,
        "depth": 100,
    }


def to_json(mode, i, level, moves):
    w, h = level["w"], level["h"]
    grid = [[EMPTY] * w for _ in range(h)]
    for x, y in level["walls"]:
        if inb(x, y, w, h):
            grid[y][x] = WALL
    for x, y in level["targets"]:
        grid[y][x] = TARGET
    return {
        "id": i,
        "mode": mode,
        "name": f"{mode.title()} {i}",
        "width": w,
        "height": h,
        "grid": grid,
        "cubes": [[x, y] for x, y in sorted(level["cubes"])],
        "player": [level["player"][0], level["player"][1]],
        "min_moves": moves,
        "difficulty": moves + len(level["cubes"]) * 6 + int(wall_density(level) * 40),
        "wall_density": round(wall_density(level), 3),
    }


def generate_one(rng, mode: str, index: int):
    spec = mode_spec(mode, index)
    for dens_nudge in (0.0, -0.04, -0.08, 0.04, -0.12):
        for _try in range(28):
            level = build_maze_level(
                rng,
                spec["w"],
                spec["h"],
                spec["cubes"],
                max(0.26, spec["density"] + dens_nudge),
                spec["rev"] + rng.randint(0, 4),
            )
            if level is None:
                continue
            moves = solve(
                level["w"],
                level["h"],
                level["walls"],
                level["targets"],
                level["player"],
                level["cubes"],
                max_depth=spec["depth"],
            )
            if moves is None:
                continue
            if moves < spec["min_moves"]:
                continue
            if len(level["cubes"]) != spec["cubes"]:
                continue
            level["moves"] = moves
            return level
    return None


def emergency_maze(rng, mode: str, index: int):
    spec = mode_spec(mode, index)
    for n in range(spec["cubes"], 1, -1):
        for dens in (0.48, 0.40, 0.34, 0.28):
            for rev in (spec["rev"], max(4, spec["rev"] // 2), 5):
                level = build_maze_level(rng, spec["w"], spec["h"], n, dens, rev)
                if level is None:
                    continue
                moves = solve(
                    level["w"],
                    level["h"],
                    level["walls"],
                    level["targets"],
                    level["player"],
                    level["cubes"],
                    max_depth=spec["depth"] + 20,
                )
                if moves is not None and moves >= 3:
                    level["moves"] = moves
                    return level
    return None


def gen_mode(mode: str, seed: int):
    out = ROOT / mode
    out.mkdir(parents=True, exist_ok=True)
    for old in out.glob("level_*.json"):
        old.unlink()
    rng = random.Random(seed)
    cubes_l, moves_l, dens_l = [], [], []
    t0 = time.time()
    for i in range(1, PER_MODE + 1):
        level = generate_one(rng, mode, i - 1)
        if level is None:
            level = emergency_maze(rng, mode, i - 1)
        if level is None:
            raise RuntimeError(f"Failed to build {mode} level {i}")
        (out / f"level_{i:03d}.json").write_text(
            json.dumps(to_json(mode, i, level, int(level["moves"])), indent=2) + "\n"
        )
        cubes_l.append(len(level["cubes"]))
        moves_l.append(int(level["moves"]))
        dens_l.append(wall_density(level))
        print(
            f"  [{mode}] {i}/{PER_MODE} cubes={cubes_l[-1]} "
            f"moves={moves_l[-1]} walls={dens_l[-1]:.0%}",
            flush=True,
        )
    print(
        f"{mode}: {time.time() - t0:.1f}s | cubes {min(cubes_l)}-{max(cubes_l)} "
        f"| moves {min(moves_l)}-{max(moves_l)} avg {sum(moves_l) / len(moves_l):.1f} "
        f"| wall density avg {sum(dens_l) / len(dens_l):.0%}",
        flush=True,
    )


def main():
    ROOT.mkdir(parents=True, exist_ok=True)
    for old in ROOT.glob("level_*.json"):
        old.unlink()
    print("Generating denser Easy / Hard / Crazy…", flush=True)
    gen_mode("easy", 401)
    gen_mode("hard", 502)
    gen_mode("crazy", 603)
    print("Done →", ROOT, flush=True)


if __name__ == "__main__":
    main()
