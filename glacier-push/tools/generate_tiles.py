#!/usr/bin/env python3
"""Generate Boxxle/Ice-Puzzle style beveled tiles (like classic ice cubesets)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets" / "tiles"
OUT.mkdir(parents=True, exist_ok=True)
S = 128  # crisp pixel-scale tile; Godot scales up


def new_img():
    return Image.new("RGBA", (S, S), (0, 0, 0, 0))


def bevel_block(
    top=(200, 240, 255),
    face=(140, 210, 240),
    left=(90, 160, 200),
    bottom=(60, 120, 170),
    right=(110, 180, 215),
    cracks=True,
    bevel=18,
) -> Image.Image:
    """Classic isometric-ish 2D bevel cube (top-left light, bottom-right dark)."""
    img = new_img()
    d = ImageDraw.Draw(img)
    b = bevel
    # face fill
    d.rectangle([0, 0, S - 1, S - 1], fill=(*face, 255))
    # top bevel strip
    d.polygon([(0, 0), (S - 1, 0), (S - 1 - b, b), (b, b)], fill=(*top, 255))
    # left bevel
    d.polygon([(0, 0), (b, b), (b, S - 1 - b), (0, S - 1)], fill=(*left, 255))
    # right bevel
    d.polygon([(S - 1, 0), (S - 1, S - 1), (S - 1 - b, S - 1 - b), (S - 1 - b, b)], fill=(*right, 255))
    # bottom bevel
    d.polygon([(0, S - 1), (b, S - 1 - b), (S - 1 - b, S - 1 - b), (S - 1, S - 1)], fill=(*bottom, 255))
    # inner face (slightly lighter plate)
    m = b + 2
    d.rectangle([m, m, S - 1 - m, S - 1 - m], fill=(min(255, face[0] + 25), min(255, face[1] + 20), min(255, face[2] + 15), 255))
    # highlight edge on top-left inner
    d.line([(m, m), (S - 1 - m, m)], fill=(255, 255, 255, 180), width=2)
    d.line([(m, m), (m, S - 1 - m)], fill=(230, 250, 255, 140), width=2)

    if cracks:
        # jagged fissures like the reference
        crack = (50, 110, 160, 220)
        d.line([(40, 36), (48, 70), (42, 95)], fill=crack, width=2)
        d.line([(48, 70), (70, 78)], fill=crack, width=2)
        d.line([(78, 42), (88, 88), (95, 100)], fill=crack, width=2)
        d.line([(55, 90), (75, 98), (72, 110)], fill=(70, 130, 175, 180), width=1)

    # outer outline
    d.rectangle([0, 0, S - 1, S - 1], outline=(40, 90, 140, 255))
    return img


def make_ice_cube():
    img = bevel_block(
        top=(220, 245, 255),
        face=(150, 220, 245),
        left=(100, 175, 215),
        bottom=(55, 125, 175),
        right=(120, 195, 225),
        cracks=True,
        bevel=20,
    )
    img.save(OUT / "ice_cube.png")


def make_ice_hot():
    """On-target: warmer rim."""
    img = bevel_block(
        top=(255, 245, 200),
        face=(180, 230, 250),
        left=(120, 180, 210),
        bottom=(70, 130, 170),
        right=(140, 200, 220),
        cracks=True,
        bevel=20,
    )
    d = ImageDraw.Draw(img)
    d.rectangle([18, 18, S - 19, S - 19], outline=(255, 180, 60, 220), width=4)
    img.save(OUT / "ice_cube_hot.png")


def make_wall():
    # Deeper blue stone/ice wall — denser bevel
    img = bevel_block(
        top=(160, 190, 230),
        face=(90, 130, 190),
        left=(60, 95, 150),
        bottom=(35, 65, 110),
        right=(75, 115, 170),
        cracks=False,
        bevel=16,
    )
    d = ImageDraw.Draw(img)
    # subtle brick lines
    d.line([(16, S // 2), (S - 17, S // 2)], fill=(40, 70, 120, 100), width=2)
    d.line([(S // 2, 16), (S // 2, S - 17)], fill=(40, 70, 120, 80), width=2)
    img.save(OUT / "wall.png")


def make_floor(variant: int):
    img = new_img()
    d = ImageDraw.Draw(img)
    if variant == 0:
        base = (210, 235, 250, 255)
        tint = (190, 225, 245, 255)
    else:
        base = (195, 228, 245, 255)
        tint = (175, 215, 238, 255)
    d.rectangle([0, 0, S - 1, S - 1], fill=base)
    # soft inset
    d.rectangle([4, 4, S - 5, S - 5], fill=tint)
    d.rectangle([4, 4, S - 5, S - 5], outline=(150, 195, 220, 180))
    # tiny sparkle dots
    for x, y in [(20, 24), (90, 40), (50, 88), (100, 100)]:
        d.point((x, y), fill=(255, 255, 255, 160))
    img.save(OUT / f"floor_{variant}.png")


def make_target():
    img = make_floor.__wrapped__ if False else None
    img = new_img()
    # reuse floor look
    flo = Image.open(OUT / "floor_0.png") if (OUT / "floor_0.png").exists() else None
    if flo:
        img = flo.copy()
    else:
        make_floor(0)
        img = Image.open(OUT / "floor_0.png").copy()
    d = ImageDraw.Draw(img)
    # gold goal plate with bevel
    m = 28
    d.ellipse([m, m, S - m, S - m], fill=(255, 210, 70, 255))
    d.ellipse([m + 6, m + 6, S - m - 6, S - m - 6], outline=(255, 150, 40, 255), width=4)
    d.ellipse([m + 14, m + 14, m + 40, m + 36], fill=(255, 255, 255, 150))
    d.ellipse([m, m, S - m, S - m], outline=(180, 100, 20, 255), width=2)
    img.save(OUT / "target.png")


def make_player():
    img = new_img()
    d = ImageDraw.Draw(img)
    # soft shadow
    d.ellipse([24, 95, 104, 120], fill=(0, 0, 0, 40))
    # ears
    d.ellipse([28, 18, 58, 50], fill=(250, 245, 240, 255))
    d.ellipse([70, 18, 100, 50], fill=(250, 245, 240, 255))
    d.ellipse([34, 24, 52, 42], fill=(255, 160, 190, 255))
    d.ellipse([76, 24, 94, 42], fill=(255, 160, 190, 255))
    # head
    d.ellipse([22, 28, 106, 112], fill=(250, 245, 240, 255))
    d.ellipse([35, 38, 70, 65], fill=(255, 255, 255, 90))
    # blush / eyes / nose
    d.ellipse([32, 68, 50, 82], fill=(255, 150, 180, 150))
    d.ellipse([78, 68, 96, 82], fill=(255, 150, 180, 150))
    d.ellipse([44, 55, 56, 72], fill=(40, 35, 60, 255))
    d.ellipse([72, 55, 84, 72], fill=(40, 35, 60, 255))
    d.ellipse([46, 57, 51, 62], fill=(255, 255, 255, 220))
    d.ellipse([74, 57, 79, 62], fill=(255, 255, 255, 220))
    d.ellipse([56, 72, 72, 86], fill=(40, 35, 60, 255))
    d.arc([48, 80, 80, 100], 10, 170, fill=(40, 35, 60, 255), width=2)
    img.save(OUT / "player.png")


def main():
    make_ice_cube()
    make_ice_hot()
    make_wall()
    make_floor(0)
    make_floor(1)
    make_target()
    make_player()
    print("Beveled ice tiles →", OUT)
    for p in sorted(OUT.glob("*.png")):
        print(f"  {p.name:20s} {p.stat().st_size:6d}b")


if __name__ == "__main__":
    main()
