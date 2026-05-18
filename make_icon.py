#!/usr/bin/env python3
"""
Processes the app icon image provided by the user.
Finds the source image, trims white border, resizes to 1024x1024 and saves it.
"""
import os
import sys
from PIL import Image

# Try to find any recently modified image or use the existing icon path
# The user's icon image needs to be placed at source_path first
source_candidates = [
    os.path.expanduser("~/Desktop/app_icon_source.png"),
    os.path.expanduser("~/Desktop/app_icon_source.jpg"),
    os.path.expanduser("~/Downloads/app_icon_source.png"),
    os.path.expanduser("~/Downloads/app_icon_source.jpg"),
]

dest = "/Users/mithil/Desktop/MITWPU_group11/Group_11_Revisio/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png"

found = None
for c in source_candidates:
    if os.path.exists(c):
        found = c
        break

if not found:
    print("ERROR: No source image found. Please save the icon image to ~/Desktop/app_icon_source.png")
    sys.exit(1)

print(f"Using source: {found}")
img = Image.open(found).convert("RGBA")

# Trim white/transparent borders by finding the bounding box of non-white pixels
bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
diff = Image.new("RGBA", img.size)
for x in range(img.width):
    for y in range(img.height):
        px = img.getpixel((x, y))
        # Consider a pixel "content" if it's not near-white
        if px[0] < 240 or px[1] < 240 or px[2] < 240:
            diff.putpixel((x, y), px)

bbox = diff.getbbox()
if bbox:
    img = img.crop(bbox)

# Resize to exactly 1024x1024
img = img.resize((1024, 1024), Image.LANCZOS)

# Convert to RGB (no alpha for app icons)
final = Image.new("RGB", (1024, 1024), (255, 255, 255))
final.paste(img, mask=img.split()[3] if img.mode == "RGBA" else None)
final.save(dest, "PNG", optimize=True)
print(f"Saved icon to: {dest}")
