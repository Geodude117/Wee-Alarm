"""Turns raw simulator screenshots into captioned App Store screenshots.

Usage: make_screenshots.py <raw_dir> <out_dir> <font_bold.woff> <font_semi.woff>
Raw files are named 01-home.png, 02-alarm.png ... (1320x2868 from iPhone 18 Pro Max).
Writes flattened RGB PNGs for each required iPhone display size.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

raw_dir, out_dir, bold_path, semi_path = sys.argv[1:5]

SIZES = {
    "iPhone-6.9-inch": (1320, 2868),
    "iPhone-6.5-inch": (1284, 2778),
    "iPhone-6.3-inch": (1206, 2622),
    "iPhone-6.1-inch": (1179, 2556),
}

CAPTIONS = {
    "01-home": ("Never forget", "the wee break"),
    "02-alarm": ("Rings even", "on silent"),
    "03-overdue": ("Knows when", "it's time"),
    "04-letout": ("One tap and", "the timer restarts"),
    "05-setup": ("Set up", "in seconds"),
    "06-settings": ("Quiet nights,", "no alarms"),
}

YELLOW = (255, 204, 51)
YELLOW_LIGHT = (255, 226, 128)
INK = (40, 33, 30)
DEEP = (236, 150, 10)


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.width - 1, img.height - 1], radius=radius, fill=255)
    return mask


def make(raw_path, size, caption):
    w, h = size
    canvas = Image.new("RGB", (w, h), YELLOW)
    # Soft vertical glow
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse([-w * 0.3, h * 0.05, w * 1.3, h * 0.75], fill=255)
    glow = glow.filter(ImageFilter.GaussianBlur(w * 0.18))
    canvas = Image.composite(Image.new("RGB", (w, h), YELLOW_LIGHT), canvas, glow)
    d = ImageDraw.Draw(canvas)

    line1, line2 = caption
    f = ImageFont.truetype(bold_path, int(w * 0.105))
    d.text((w / 2, h * 0.075), line1, font=f, fill=INK, anchor="mm")
    d.text((w / 2, h * 0.075 + w * 0.12), line2, font=f, fill=DEEP, anchor="mm")

    # Screenshot as a rounded "phone" card with a dark bezel and shadow
    shot = Image.open(raw_path).convert("RGB")
    sw = int(w * 0.80)
    sh = int(shot.height * sw / shot.width)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    bezel = int(w * 0.022)
    radius = int(sw * 0.13)
    x = (w - sw) // 2
    y = int(h * 0.205)

    shadow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(shadow).rounded_rectangle(
        [x - bezel, y - bezel + w * 0.02, x + sw + bezel, y + sh + bezel + w * 0.02],
        radius=radius + bezel, fill=110)
    shadow = shadow.filter(ImageFilter.GaussianBlur(w * 0.03))
    canvas = Image.composite(Image.new("RGB", (w, h), (150, 105, 20)), canvas, shadow)

    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle([x - bezel, y - bezel, x + sw + bezel, y + sh + bezel], radius=radius + bezel, fill=(28, 26, 30))
    canvas.paste(shot, (x, y), rounded(shot, radius))
    return canvas


os.makedirs(out_dir, exist_ok=True)
for folder, size in SIZES.items():
    path = os.path.join(out_dir, folder)
    os.makedirs(path, exist_ok=True)
    for name, caption in CAPTIONS.items():
        raw = os.path.join(raw_dir, name + ".png")
        make(raw, size, caption).save(os.path.join(path, name + ".png"), optimize=True)
    print("saved", folder)
