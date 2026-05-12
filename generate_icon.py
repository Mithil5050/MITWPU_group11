#!/usr/bin/env python3
"""
Generates the Revisio app icon (robot face with cyan eyes) at 1024x1024.
Reference: dark navy screen with cyan glowing downward-curved arcs as eyes,
corner bracket markers, inside a smooth metallic gray rounded frame.
"""
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
dest = "/Users/mithil/Desktop/MITWPU_group11/Group_11_Revisio/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ── Outer metallic frame (smooth gradient) ────────────────────────────────────
frame_r = 220
for i in range(90):
    t = i / 90
    # metallic silver-blue gradient
    r = int(155 + 30 * math.sin(t * 3.14)) if False else int(158 - 18 * t)
    g = int(163 - 16 * t)
    b = int(172 - 14 * t)
    draw.rounded_rectangle(
        [i, i, SIZE - i, SIZE - i],
        radius=max(10, frame_r - i * 1.2),
        fill=(r, g, b, 255)
    )

# Rim highlight (top-left lighter edge)
rim = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
rd = ImageDraw.Draw(rim)
rd.rounded_rectangle([0, 0, SIZE, SIZE], radius=frame_r, fill=(255, 255, 255, 40))
rd.rounded_rectangle([6, 6, SIZE - 6, SIZE - 6], radius=frame_r - 6, fill=(0, 0, 0, 0))
img = Image.alpha_composite(img, rim)
draw = ImageDraw.Draw(img)

# ── Inner dark screen ─────────────────────────────────────────────────────────
pad = 92
screen_r = 155
screen_box = [pad, pad, SIZE - pad, SIZE - pad]
draw.rounded_rectangle(screen_box, radius=screen_r, fill=(8, 16, 28, 255))

# ── Subtle screen glare (very soft, small) ────────────────────────────────────
glare = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(glare)
gd.ellipse([pad + 60, pad + 50, pad + 260, pad + 100], fill=(255, 255, 255, 18))
glare = glare.filter(ImageFilter.GaussianBlur(30))
img = Image.alpha_composite(img, glare)
draw = ImageDraw.Draw(img)

# ── Helper: draw glowing arc ──────────────────────────────────────────────────
CYAN = (0, 225, 235)

def draw_glow_arc(base_img, cx, cy, r, arc_start, arc_end, width=24):
    """Layer multiple blurred arcs to create a neon glow effect."""
    for g_w, alpha in [(80, 25), (55, 40), (35, 60), (20, 90)]:
        glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        gd2 = ImageDraw.Draw(glow)
        gd2.arc(
            [cx - r, cy - r, cx + r, cy + r],
            start=arc_start, end=arc_end,
            fill=(*CYAN, alpha),
            width=width + g_w
        )
        glow = glow.filter(ImageFilter.GaussianBlur(g_w // 8))
        base_img.alpha_composite(glow)
    # Crisp core arc
    d = ImageDraw.Draw(base_img)
    d.arc(
        [cx - r, cy - r, cx + r, cy + r],
        start=arc_start, end=arc_end,
        fill=(*CYAN, 255),
        width=width
    )

# ── Eyes: downward-curved arcs (like ^^ closed happy eyes) ───────────────────
# In PIL arc: 0° = 3 o'clock, 90° = 6 o'clock.
# For a downward smile arc (∩ shape), use 180°→360° (top half of circle).
# That gives us the "^" eye shape seen in the reference image.
eye_y = SIZE // 2 - 10   # centered in screen
eye_r = 108
left_cx  = SIZE // 2 - 145
right_cx = SIZE // 2 + 145

# 180→360 draws the top semicircle (∩ shape = closed/happy eye)
draw_glow_arc(img, left_cx,  eye_y, eye_r, 180, 360, width=26)
draw_glow_arc(img, right_cx, eye_y, eye_r, 180, 360, width=26)
draw = ImageDraw.Draw(img)

# ── Corner bracket markers ────────────────────────────────────────────────────
bk_pad = 110
bk_len = 60
bk_w   = 11
bk_col = (*CYAN, 255)

corners = [
    (pad + bk_pad, pad + bk_pad),
    (SIZE - pad - bk_pad, pad + bk_pad),
    (pad + bk_pad, SIZE - pad - bk_pad),
    (SIZE - pad - bk_pad, SIZE - pad - bk_pad),
]
directions = [(1, 1), (-1, 1), (1, -1), (-1, -1)]

for (cx, cy), (dx, dy) in zip(corners, directions):
    draw.line([(cx, cy), (cx + dx * bk_len, cy)], fill=bk_col, width=bk_w)
    draw.line([(cx, cy), (cx, cy + dy * bk_len)], fill=bk_col, width=bk_w)

# ── Final: convert to RGB and save ───────────────────────────────────────────
bg = Image.new("RGB", (SIZE, SIZE), (255, 255, 255))
bg.paste(img, mask=img.split()[3])
bg.save(dest, "PNG", optimize=True)
print(f"Icon saved to: {dest}")

import math
