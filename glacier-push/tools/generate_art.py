#!/usr/bin/env python3
"""Generate Candy-Crush-inspired glossy title-screen art for Glacier Push."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parents[1] / "assets" / "ui"
OUT.mkdir(parents=True, exist_ok=True)
RNG = random.Random(42)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def vert_gradient(size, top, bottom):
    img = Image.new("RGBA", size)
    w, h = size
    px = img.load()
    for y in range(h):
        c = lerp(top, bottom, y / max(h - 1, 1))
        for x in range(w):
            px[x, y] = c if len(c) == 4 else (*c, 255)
    return img


def draw_ellipse_gloss(draw, bbox, fill, highlight=True):
    draw.ellipse(bbox, fill=fill)
    if highlight:
        x0, y0, x1, y1 = bbox
        w = x1 - x0
        h = y1 - y0
        hx0 = x0 + w * 0.18
        hy0 = y0 + h * 0.12
        hx1 = x0 + w * 0.62
        hy1 = y0 + h * 0.45
        draw.ellipse([hx0, hy0, hx1, hy1], fill=(255, 255, 255, 110))


def soft_circle(img, cx, cy, r, color, blur=8):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=color)
    if blur:
        layer = layer.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(img, layer)


def make_background(w=1080, h=1920):
    img = vert_gradient((w, h), (126, 214, 255, 255), (255, 182, 220, 255))
    # sun glow
    img = soft_circle(img, int(w * 0.78), int(h * 0.16), 180, (255, 255, 200, 90), 40)
    d = ImageDraw.Draw(img)

    # fluffy clouds
    for cx, cy, s in [(180, 220, 90), (420, 160, 110), (700, 240, 80), (920, 180, 100), (300, 340, 70)]:
        for ox, oy, sc in [(-0.5, 0.1, 0.7), (0, 0, 1), (0.55, 0.05, 0.75), (0.15, -0.35, 0.55)]:
            r = int(s * sc)
            draw_ellipse_gloss(
                d,
                [cx + ox * s - r, cy + oy * s - r * 0.7, cx + ox * s + r, cy + oy * s + r * 0.7],
                (255, 255, 255, 230),
            )

    # rolling hills (layered)
    hill_colors = [
        (90, 210, 140, 255),
        (70, 190, 120, 255),
        (110, 230, 160, 255),
    ]
    for i, col in enumerate(hill_colors):
        layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        base_y = int(h * (0.58 + i * 0.06))
        pts = [(0, h), (0, base_y)]
        for x in range(0, w + 1, 40):
            wave = math.sin(x * 0.008 + i) * 50 + math.sin(x * 0.02 + i * 2) * 25
            pts.append((x, int(base_y + wave)))
        pts += [(w, h)]
        ld.polygon(pts, fill=col)
        img = Image.alpha_composite(img, layer)

    # winding path
    path = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    pd = ImageDraw.Draw(path)
    for y in range(int(h * 0.62), h, 8):
        t = (y - h * 0.62) / (h * 0.38)
        cx = w * 0.5 + math.sin(t * 3.2) * 90
        rw = 70 + t * 110
        pd.ellipse([cx - rw, y - 18, cx + rw, y + 18], fill=(210, 160, 110, 230))
    path = path.filter(ImageFilter.GaussianBlur(1))
    img = Image.alpha_composite(img, path)

    # candy / ice jewel piles (left & right)
    jewel_colors = [
        (255, 95, 168), (77, 183, 255), (255, 230, 102),
        (181, 124, 255), (255, 140, 66), (120, 255, 200), (255, 120, 120),
    ]
    for side, base_x in [("L", 40), ("R", w - 280)]:
        for i in range(18):
            col = jewel_colors[i % len(jewel_colors)]
            jx = base_x + RNG.randint(0, 220)
            jy = int(h * 0.72) + RNG.randint(0, 380)
            jr = RNG.randint(28, 58)
            shape = RNG.choice(["round", "oval", "diamond"])
            jewel = Image.new("RGBA", (w, h), (0, 0, 0, 0))
            jd = ImageDraw.Draw(jewel)
            # shadow
            jd.ellipse([jx - jr + 6, jy - jr * 0.4 + 10, jx + jr + 6, jy + jr * 0.55 + 10], fill=(0, 0, 0, 50))
            if shape == "round":
                draw_ellipse_gloss(jd, [jx - jr, jy - jr, jx + jr, jy + jr], (*col, 255))
            elif shape == "oval":
                draw_ellipse_gloss(jd, [jx - jr, jy - int(jr * 0.7), jx + jr, jy + int(jr * 0.7)], (*col, 255))
            else:
                pts = [
                    (jx, jy - jr), (jx + jr, jy), (jx, jy + jr), (jx - jr, jy),
                ]
                jd.polygon(pts, fill=(*col, 255))
                jd.polygon([(jx, jy - jr * 0.4), (jx + jr * 0.35, jy - jr * 0.1), (jx, jy + jr * 0.1)], fill=(255, 255, 255, 100))
            img = Image.alpha_composite(img, jewel)

    img.save(OUT / "title_bg.png")
    print("wrote title_bg.png")
    return img


def make_cloud():
    img = Image.new("RGBA", (320, 180), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for cx, cy, r in [(90, 100, 55), (150, 85, 70), (220, 100, 50), (120, 70, 40)]:
        draw_ellipse_gloss(d, [cx - r, cy - r * 0.7, cx + r, cy + r * 0.7], (255, 255, 255, 245))
    img.save(OUT / "cloud.png")
    print("wrote cloud.png")


def make_mascot():
    """Cute glossy polar bear mascot."""
    s = 512
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # shadow
    d.ellipse([110, 400, 400, 480], fill=(0, 0, 0, 40))
    # ears
    for ex in [140, 300]:
        d.ellipse([ex, 70, ex + 90, 160], fill=(255, 250, 245, 255))
        d.ellipse([ex + 18, 90, ex + 72, 140], fill=(255, 180, 200, 255))
    # head
    d.ellipse([90, 110, 420, 440], fill=(255, 250, 245, 255))
    # gloss
    d.ellipse([140, 140, 280, 240], fill=(255, 255, 255, 90))
    # cheeks
    d.ellipse([130, 280, 190, 330], fill=(255, 150, 180, 180))
    d.ellipse([320, 280, 380, 330], fill=(255, 150, 180, 180))
    # eyes
    d.ellipse([180, 230, 220, 280], fill=(40, 30, 60, 255))
    d.ellipse([290, 230, 330, 280], fill=(40, 30, 60, 255))
    d.ellipse([192, 238, 208, 255], fill=(255, 255, 255, 230))
    d.ellipse([302, 238, 318, 255], fill=(255, 255, 255, 230))
    # nose
    d.ellipse([230, 290, 280, 330], fill=(40, 30, 60, 255))
    d.ellipse([240, 298, 258, 312], fill=(255, 255, 255, 120))
    # smile
    d.arc([200, 310, 310, 380], 20, 160, fill=(40, 30, 60, 255), width=6)
    img.save(OUT / "mascot_bear.png")
    print("wrote mascot_bear.png")


def make_pill_button(path: Path, color, size=(900, 220), label: str | None = None):
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # drop shadow
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle([8, 16, w - 4, h - 2], radius=h // 2, fill=(0, 0, 0, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    img = Image.alpha_composite(img, shadow)

    d = ImageDraw.Draw(img)
    # body
    d.rounded_rectangle([0, 0, w - 12, h - 18], radius=(h - 18) // 2, fill=(*color, 255))
    # bottom shade
    shade = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shd = ImageDraw.Draw(shade)
    shd.rounded_rectangle([0, (h - 18) // 2, w - 12, h - 18], radius=(h - 18) // 2, fill=(0, 0, 0, 45))
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w - 12, h - 18], radius=(h - 18) // 2, fill=255)
    shade.putalpha(Image.composite(shade.split()[-1], Image.new("L", (w, h), 0), mask))
    img = Image.alpha_composite(img, shade)
    # top gloss highlight
    gloss = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gloss)
    gd.rounded_rectangle([18, 10, w - 30, (h - 18) * 0.42], radius=40, fill=(255, 255, 255, 100))
    gloss = gloss.filter(ImageFilter.GaussianBlur(2))
    img = Image.alpha_composite(img, gloss)

    if label:
        # try system fonts
        font = None
        for fp in [
            "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/Library/Fonts/Arial Bold.ttf",
        ]:
            if Path(fp).exists():
                try:
                    font = ImageFont.truetype(fp, 72)
                    break
                except Exception:
                    pass
        if font is None:
            font = ImageFont.load_default()
        td = ImageDraw.Draw(img)
        bbox = td.textbbox((0, 0), label, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        tx = (w - 12 - tw) // 2
        ty = (h - 18 - th) // 2 - 4
        # text shadow
        td.text((tx + 2, ty + 3), label, font=font, fill=(0, 0, 0, 80))
        td.text((tx, ty), label, font=font, fill=(255, 255, 255, 255))

    img.save(path)
    print("wrote", path.name)


def make_title_banner():
    w, h = 980, 320
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # hanging cord
    d = ImageDraw.Draw(img)
    d.line([(w // 2, 0), (w // 2, 36)], fill=(120, 70, 40, 255), width=8)

    # board shadow
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([30, 50, w - 20, h - 10], radius=40, fill=(0, 0, 0, 60))
    shadow = shadow.filter(ImageFilter.GaussianBlur(6))
    img = Image.alpha_composite(img, shadow)

    d = ImageDraw.Draw(img)
    # wooden / candy board
    d.rounded_rectangle([20, 36, w - 30, h - 24], radius=40, fill=(255, 214, 90, 255))
    d.rounded_rectangle([34, 50, w - 44, h - 38], radius=32, fill=(255, 230, 130, 255))
    # inner rim
    d.rounded_rectangle([34, 50, w - 44, h - 38], radius=32, outline=(196, 90, 30, 255), width=6)

    font = None
    for fp in [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Impact.ttf",
    ]:
        if Path(fp).exists():
            try:
                font = ImageFont.truetype(fp, 96)
                break
            except Exception:
                pass
    if font is None:
        font = ImageFont.load_default()

    text = "Glacier Push"
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (w - tw) // 2 - 5
    ty = (h - th) // 2 + 8
    # thick outline
    outline = (180, 60, 20, 255)
    for ox in range(-4, 5):
        for oy in range(-4, 5):
            if ox * ox + oy * oy <= 20:
                d.text((tx + ox, ty + oy), text, font=font, fill=outline)
    d.text((tx, ty), text, font=font, fill=(255, 250, 220, 255))

    # heart-ish gem in the middle-ish of title area (decorate)
    d.ellipse([w - 120, 70, w - 70, 120], fill=(255, 80, 120, 255))
    d.ellipse([w - 112, 78, w - 96, 94], fill=(255, 255, 255, 140))

    img.save(OUT / "title_banner.png")
    print("wrote title_banner.png")


def make_panel():
    w, h = 920, 280
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([10, 14, w - 4, h - 4], radius=36, fill=(0, 0, 0, 50))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    img = Image.alpha_composite(img, shadow)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w - 16, h - 20], radius=36, fill=(255, 255, 255, 210))
    d.rounded_rectangle([12, 12, w - 28, h - 32], radius=28, outline=(255, 255, 255, 255), width=4)
    img.save(OUT / "panel_soft.png")
    print("wrote panel_soft.png")


def main():
    make_background()
    make_cloud()
    make_mascot()
    make_title_banner()
    make_panel()
    make_pill_button(OUT / "btn_play.png", (255, 70, 160), label="Play!")
    make_pill_button(OUT / "btn_continue.png", (70, 170, 255), label="Continue!")
    make_pill_button(OUT / "btn_levels.png", (170, 100, 255), label="Levels")
    make_pill_button(OUT / "btn_premium.png", (255, 170, 60), size=(900, 180), label="Remove Ads · $1.99")
    # blank glossy for runtime text overrides
    make_pill_button(OUT / "btn_play_blank.png", (255, 70, 160))
    make_pill_button(OUT / "btn_continue_blank.png", (70, 170, 255))
    print("All UI art written to", OUT)


if __name__ == "__main__":
    main()
