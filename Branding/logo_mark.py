"""Draws the Wee Alarm dog-in-clock mark (shared by make_logo.py and make_store_assets.py)."""
import math

YELLOW = (255, 204, 51)
YELLOW_LIGHT = (255, 221, 110)
FUR = (225, 168, 107)
EAR = (143, 92, 56)
PATCH = (184, 128, 87)
MUZZLE = (252, 237, 214)
INK = (40, 33, 30)
WHITE = (255, 253, 247)
BLUSH = (255, 160, 150)
TONGUE = (250, 120, 140)


def draw_mark(d, S, ox=0.0, oy=0.0):
    """Draw the mark into an S x S box whose top-left is (ox, oy)."""
    def P(x, y):  # fractional coords -> pixels
        return ox + x * S, oy + y * S

    def ellipse(x, y, w, h, fill, outline=None, width=0):
        x0, y0 = P(x - w / 2, y - h / 2)
        x1, y1 = P(x + w / 2, y + h / 2)
        d.ellipse([x0, y0, x1, y1], fill=fill, outline=outline, width=int(width * S))

    def rotated_ellipse(x, y, w, h, angle, fill, pivot=(0, -0.5)):
        a = math.radians(angle)
        px, py = x + pivot[0] * w, y + pivot[1] * h
        pts = []
        for i in range(160):
            t = 2 * math.pi * i / 160
            ex, ey = x + w / 2 * math.cos(t), y + h / 2 * math.sin(t)
            dx, dy = ex - px, ey - py
            pts.append(P(px + dx * math.cos(a) - dy * math.sin(a),
                         py + dx * math.sin(a) + dy * math.cos(a)))
        d.polygon(pts, fill=fill)

    def thick_line(x0, y0, x1, y1, w, fill):
        d.line([P(x0, y0), P(x1, y1)], fill=fill, width=int(w * S))
        ellipse(x0, y0, w, w, fill)
        ellipse(x1, y1, w, w, fill)

    cx, cy = 0.5, 0.55   # clock centre
    R = 0.34             # clock radius

    # Ring lines either side of the bells ("it's ringing")
    for r in (0.46, 0.52):
        x0, y0 = P(cx - r, cy - r)
        x1, y1 = P(cx + r, cy - r + 2 * r)
        d.arc([x0, y0, x1, y1], 196, 214, fill=INK, width=int(0.022 * S))
        d.arc([x0, y0, x1, y1], 326, 344, fill=INK, width=int(0.022 * S))

    # Legs
    thick_line(cx - 0.2, cy + 0.27, cx - 0.27, cy + 0.38, 0.05, INK)
    thick_line(cx + 0.2, cy + 0.27, cx + 0.27, cy + 0.38, 0.05, INK)

    # Bells: domes sitting on the rim, pointing outwards at ±42° from vertical
    for side in (-1, 1):
        a = math.radians(side * 42)
        ux, uy = math.sin(a), -math.cos(a)      # outward
        px, py = math.cos(a), math.sin(a)       # along the base
        bx, by = cx + ux * (R + 0.005), cy + uy * (R + 0.005)
        w, h = 0.22, 0.13
        pts = []
        for i in range(81):
            t = math.pi * i / 80
            x, y = w / 2 * math.cos(t), h * math.sin(t)
            pts.append(P(bx + px * x + ux * y, by + py * x + uy * y))
        d.polygon(pts, fill=INK)
        ellipse(bx + ux * (h + 0.012), by + uy * (h + 0.012), 0.045, 0.045, INK)
    thick_line(cx, cy - R - 0.02, cx, cy - R - 0.075, 0.035, INK)
    ellipse(cx, cy - R - 0.09, 0.07, 0.04, INK)

    # Clock body
    ellipse(cx, cy, 2 * R + 0.05, 2 * R + 0.05, INK)
    ellipse(cx, cy, 2 * R - 0.01, 2 * R - 0.01, WHITE)

    # Dog face inside the clock
    s = 0.56
    fy = cy + 0.025
    rotated_ellipse(cx - s * 0.33, fy - s * 0.1, s * 0.25, s * 0.44, 18, EAR)
    rotated_ellipse(cx + s * 0.33, fy - s * 0.1, s * 0.25, s * 0.44, -18, EAR)
    ellipse(cx, fy, s * 0.8, s * 0.8, FUR)
    ellipse(cx + s * 0.155, fy - s * 0.075, s * 0.22, s * 0.2, PATCH)
    ellipse(cx - s * 0.23, fy + s * 0.1, s * 0.09, s * 0.09, BLUSH)
    ellipse(cx + s * 0.23, fy + s * 0.1, s * 0.09, s * 0.09, BLUSH)
    ellipse(cx, fy + s * 0.165, s * 0.47, s * 0.33, MUZZLE)
    for side in (-1, 1):
        ex, ey = cx + side * s * 0.145, fy - s * 0.065
        ellipse(ex, ey, s * 0.095, s * 0.095, INK)
        ellipse(ex + s * 0.017, ey - s * 0.017, s * 0.034, s * 0.034, WHITE)
    ellipse(cx, fy + s * 0.275, s * 0.09, s * 0.12, TONGUE)
    ellipse(cx, fy + s * 0.075, s * 0.16, s * 0.105, INK)
    w = s * 0.2
    y0 = fy + s * 0.195
    x0, yy0 = P(cx - w / 2, y0 - s * 0.08)
    x1, yy1 = P(cx + w / 2, y0 + s * 0.08)
    d.arc([x0, yy0, x1, yy1], 10, 170, fill=INK, width=int(s * 0.03 * S))


