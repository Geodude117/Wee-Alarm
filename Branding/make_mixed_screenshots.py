"""Six App Store screenshots, each shown on a differently styled iPhone.

Usage: make_mixed_screenshots.py <raw_dir> <out_dir> <font_bold.woff>
Every image in a folder has the same pixel size (App Store Connect needs one size
per device slot), but each uses a different phone finish so the set looks varied.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

raw_dir, out_dir, bold_path = sys.argv[1:4]

SIZES = {
    "mixed-phones-6.9-inch": (1320, 2868),
    "mixed-phones-6.3-inch": (1206, 2622),
}

# name, caption, phone finish
SHOTS = [
    ("01-home", ("Never forget", "the wee break"),
     dict(label="Pro Max · Black Titanium", frame=(38, 38, 42), edge=(92, 92, 98), bezel=0.024, radius=0.13, bg=(255, 204, 51))),
    ("02-alarm", ("Rings even", "on silent"),
     dict(label="Air · Sky Silver", frame=(214, 218, 224), edge=(250, 251, 253), bezel=0.012, radius=0.14, bg=(255, 214, 92))),
    ("03-overdue", ("Knows when", "it's time"),
     dict(label="iPhone · Ultramarine", frame=(78, 104, 186), edge=(150, 172, 236), bezel=0.026, radius=0.12, bg=(255, 196, 46))),
    ("04-letout", ("One tap and", "the timer restarts"),
     dict(label="Pro · Desert Titanium", frame=(196, 168, 140), edge=(234, 214, 192), bezel=0.022, radius=0.13, bg=(255, 210, 70))),
    ("05-setup", ("Set up", "in seconds"),
     dict(label="iPhone · Pink", frame=(242, 182, 196), edge=(255, 222, 230), bezel=0.026, radius=0.12, bg=(255, 204, 51))),
    ("06-settings", ("Quiet nights,", "no alarms"),
     dict(label="Pro Max · Cosmic Orange", frame=(232, 116, 40), edge=(255, 170, 110), bezel=0.024, radius=0.13, bg=(255, 218, 100))),
]

INK = (40, 33, 30)
DEEP = (236, 150, 10)


def lighter(c, k):
    return tuple(min(255, int(v + (255 - v) * k)) for v in c)


def make(raw_path, size, caption, style):
    w, h = size
    bg = style["bg"]
    canvas = Image.new("RGB", (w, h), bg)
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse([-w * 0.3, h * 0.05, w * 1.3, h * 0.75], fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(w * 0.18))
    canvas = Image.composite(Image.new("RGB", (w, h), lighter(bg, 0.35)), canvas, glow)
    d = ImageDraw.Draw(canvas)

    f = ImageFont.truetype(bold_path, int(w * 0.105))
    d.text((w / 2, h * 0.075), caption[0], font=f, fill=INK, anchor="mm")
    d.text((w / 2, h * 0.075 + w * 0.12), caption[1], font=f, fill=DEEP, anchor="mm")

    shot = Image.open(raw_path).convert("RGB")
    sw = int(w * 0.76)
    sh = int(shot.height * sw / shot.width)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    bezel = int(w * style["bezel"])
    rim = max(6, int(w * 0.02))           # coloured metal edge
    radius = int(sw * style["radius"])
    x = (w - sw) // 2
    y = int(h * 0.205)

    # Shadow
    shadow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x - bezel - rim, y - bezel - rim + w * 0.02, x + sw + bezel + rim, y + sh + bezel + rim + w * 0.02],
        radius=radius + bezel + rim, fill=110)
    shadow = shadow.filter(ImageFilter.GaussianBlur(w * 0.03))
    canvas = Image.composite(Image.new("RGB", (w, h), (150, 105, 20)), canvas, shadow)
    d = ImageDraw.Draw(canvas)

    # Metal frame (outer), with a lighter highlight line, then the black glass border
    d.rounded_rectangle([x - bezel - rim, y - bezel - rim, x + sw + bezel + rim, y + sh + bezel + rim],
                        radius=radius + bezel + rim, fill=style["frame"])
    d.rounded_rectangle([x - bezel - rim // 2, y - bezel - rim // 2, x + sw + bezel + rim // 2, y + sh + bezel + rim // 2],
                        radius=radius + bezel + rim // 2, outline=style["edge"], width=max(1, rim // 3))
    d.rounded_rectangle([x - bezel, y - bezel, x + sw + bezel, y + sh + bezel], radius=radius + bezel, fill=(14, 14, 16))

    # Side buttons in the frame colour
    bw = max(4, int(w * 0.008))
    for by, bh in ((0.17, 0.05), (0.25, 0.08), (0.35, 0.08)):
        d.rounded_rectangle([x - bezel - rim - bw, y + sh * by, x - bezel - rim + 1, y + sh * (by + bh)],
                            radius=bw, fill=style["frame"])
    d.rounded_rectangle([x + sw + bezel + rim - 1, y + sh * 0.26, x + sw + bezel + rim + bw, y + sh * 0.38],
                        radius=bw, fill=style["frame"])

    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius=radius, fill=255)
    canvas.paste(shot, (x, y), mask)
    return canvas


for folder, size in SIZES.items():
    path = os.path.join(out_dir, folder)
    os.makedirs(path, exist_ok=True)
    for name, caption, style in SHOTS:
        img = make(os.path.join(raw_dir, name + ".png"), size, caption, style)
        img.save(os.path.join(path, name + ".png"), optimize=True)
    print("saved", folder)
