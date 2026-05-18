"""
Genera le icone PWA + favicon da logo Silvestre.
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOGO = os.path.join(ROOT, "app", "assets", "brand", "silvestre_logo.jpg")
WEB_DIR = os.path.join(ROOT, "app", "web")
ICONS_DIR = os.path.join(WEB_DIR, "icons")

os.makedirs(ICONS_DIR, exist_ok=True)

img = Image.open(LOGO).convert("RGB")
# Make it square (crop to center if not)
w, h = img.size
side = min(w, h)
left = (w - side) // 2
top = (h - side) // 2
img = img.crop((left, top, left + side, top + side))

# Sizes required by PWA + favicon
sizes = {
    "Icon-192.png": 192,
    "Icon-512.png": 512,
    "Icon-maskable-192.png": 192,
    "Icon-maskable-512.png": 512,
}
for name, size in sizes.items():
    resized = img.resize((size, size), Image.LANCZOS)
    resized.save(os.path.join(ICONS_DIR, name), format="PNG", optimize=True)
    print(f"  {name} ({size}x{size})")

# Favicon
fav = img.resize((64, 64), Image.LANCZOS)
fav.save(os.path.join(WEB_DIR, "favicon.png"), format="PNG", optimize=True)
print(f"  favicon.png (64x64)")

print("Done.")
