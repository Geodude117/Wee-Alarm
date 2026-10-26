"""App Store 'Header and Search Results' creative assets for Wee Alarm.

Usage: make_store_assets.py <out_dir> <font_bold.woff> <font_semibold.woff>
Writes flattened RGB PNGs (no alpha) at Apple's sizes:
  header-3840x1646.png         product page header, 21:9
  search-3840x2560.png         search results card, 3:2
  universal-5244x2950.png      16:9 image accepted by both placements
Key content sits near the centre because the placements crop differently.
"""
import math
import os
import random
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault("WEE_LOGO_IMPORT", "1")

out_dir, bold_path, semi_path = sys.argv[1], sys.argv[2], sys.argv[3]

YELLOW = (255, 204, 51)
YELLOW_LIGHT = (255, 224, 120)
DEEP = (236, 150, 10)
INK = (40, 33, 30)
CREAM = (255, 249, 232)


def load_mark(size):
    """Render the dog-in-clock mark from the logo script."""
    import importlib.util
    spec = importlib.util.spec_from_file_location("logo", os.path.join(os.path.dirname(__file__), "logo_mark.py"))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    big = size * 3
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    mod.draw_mark(ImageDraw.Draw(img), big)
    return img.resize((size, size), Image.LANCZOS)


def paw(draw, cx, cy, s, fill, angle=0):
    """A simple paw print: one pad and four toes."""
    a = math.radians(angle)

    def rot(dx, dy):
        return cx + dx * math.cos(a) - dy * math.sin(a), cy + dx * math.sin(a) + dy * math.cos(a)

    def blob(dx, dy, w, h):
        x, y = rot(dx, dy)
        draw.ellipse([x - w / 2, y - h / 2, x + w / 2, y + h / 2], fill=fill)

    blob(0, s * 0.18, s * 0.62, s * 0.5)
    for dx, dy in ((-0.36, -0.2), (-0.13, -0.42), (0.13, -0.42), (0.36, -0.2)):
        blob(dx * s, dy * s, s * 0.22, s * 0.28)


def background(w, h, seed):
    img = Image.new("RGB", (w, h), YELLOW)
    d = ImageDraw.Draw(img)
    # Soft glow behind the centre
    glow = Image.new("L", (w, h), 0)
    gd = ImageDraw.Draw(glow)
    r = min(w, h) * 0.62
    gd.ellipse([w / 2 - r * 1.4, h / 2 - r, w / 2 + r * 1.4, h / 2 + r], fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(min(w, h) * 0.12))
    img = Image.composite(Image.new("RGB", (w, h), YELLOW_LIGHT), img, glow)
    d = ImageDraw.Draw(img)
    # Scattered paw-print trail
    rnd = random.Random(seed)
    s = min(w, h) * 0.07
    for i in range(14):
        x = w * (0.03 + 0.94 * i / 13)
        y = h * (0.95 + 0.02 * math.sin(i * 0.9)) if i % 2 else h * (0.9 + 0.02 * math.sin(i * 0.9))
        paw(d, x, y, s, (246, 186, 30), angle=rnd.uniform(-25, 25) + 80)
    for i in range(10):
        x = w * (0.05 + 0.9 * i / 9)
        y = h * (0.06 + 0.02 * math.cos(i * 1.1))
        paw(d, x, y, s * 0.8, (246, 190, 40), angle=rnd.uniform(-25, 25) - 100)
    return img


def wave_circle(size, level=0.62):
    """The app's 'bladder' meter: a ringed circle part-filled with a wave."""
    big = size * 3
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, big - 1, big - 1], fill=255)
    fill = Image.new("RGBA", (big, big), (*CREAM, 255))
    fd = ImageDraw.Draw(fill)
    base = big * (1 - level)
    pts = [(0, big)]
    for i in range(121):
        x = big * i / 120
        pts.append((x, base + math.sin(i / 120 * 2 * math.pi * 1.5 + 0.6) * big * 0.025))
    pts.append((big, big))
    fd.polygon(pts, fill=(*DEEP, 255))
    pts2 = [(0, big)] + [(big * i / 120, base - big * 0.02 + math.sin(i / 120 * 2 * math.pi * 1.5 + 2.2) * big * 0.02)
                         for i in range(121)] + [(big, big)]
    layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    ImageDraw.Draw(layer).polygon(pts2, fill=(*YELLOW, 200))
    fill = Image.alpha_composite(layer, fill) if False else Image.alpha_composite(fill, layer)
    fd = ImageDraw.Draw(fill)
    fd.polygon(pts, fill=(*DEEP, 255))
    for bx, by, br in ((0.35, 0.78, 0.025), (0.55, 0.7, 0.018), (0.68, 0.84, 0.03), (0.45, 0.9, 0.015)):
        fd.ellipse([big * (bx - br), big * (by - br), big * (bx + br), big * (by + br)], fill=(255, 255, 255, 140))
    img.paste(fill, (0, 0), mask)
    ImageDraw.Draw(img).ellipse([0, 0, big - 1, big - 1], outline=(*INK, 255), width=int(big * 0.035))
    return img.resize((size, size), Image.LANCZOS)


def compose(w, h, layout, name, seed):
    img = background(w, h, seed).convert("RGBA")
    d = ImageDraw.Draw(img)
    unit = min(w, h)

    if layout == "wide":
        # Size everything from a 21:9 box so wider or taller canvases don't overflow.
        unit = min(h, w * 1646 / 3840)
        # Mark on the left of centre, headline on the right — all inside the middle 70%.
        mark_size = int(unit * 0.74)
        mark = load_mark(mark_size)
        meter = wave_circle(int(unit * 0.28))
        mx = int(w * 0.5 - mark_size * 0.98)
        my = int(h * 0.5 - mark_size * 0.52)
        img.alpha_composite(mark, (mx, my))
        img.alpha_composite(meter, (mx - int(mark_size * 0.16), my + int(mark_size * 0.64)))
        title = ImageFont.truetype(bold_path, int(unit * 0.15))
        sub = ImageFont.truetype(semi_path, int(unit * 0.06))
        tx = int(w * 0.5 + unit * 0.07)
        d.text((tx, h / 2 - unit * 0.12), "Never forget", font=title, fill=INK, anchor="lm")
        d.text((tx, h / 2 + unit * 0.03), "the wee break", font=title, fill=DEEP, anchor="lm")
        d.text((tx, h / 2 + unit * 0.17), "A dog alarm that rings, even on silent.", font=sub, fill=INK, anchor="lm")
    else:
        # Stacked: mark above, headline below, centred.
        mark_size = int(unit * 0.46)
        mark = load_mark(mark_size)
        meter = wave_circle(int(unit * 0.18))
        mx = int(w / 2 - mark_size / 2)
        my = int(h * 0.12)
        img.alpha_composite(mark, (mx, my))
        img.alpha_composite(meter, (mx + int(mark_size * 0.82), my + int(mark_size * 0.6)))
        title = ImageFont.truetype(bold_path, int(unit * 0.11))
        sub = ImageFont.truetype(semi_path, int(unit * 0.045))
        y = my + mark_size + unit * 0.09
        d.text((w / 2, y), "Never forget the wee break", font=title, fill=INK, anchor="mm")
        d.text((w / 2, y + unit * 0.11), "A dog alarm that rings, even on silent.", font=sub, fill=INK, anchor="mm")

    img.convert("RGB").save(os.path.join(out_dir, name), optimize=True)
    print("saved", name)


compose(3840, 1646, "wide", "header-3840x1646.png", 1)
compose(3840, 2560, "tall", "search-3840x2560.png", 2)
compose(5244, 2950, "wide", "universal-5244x2950.png", 3)
