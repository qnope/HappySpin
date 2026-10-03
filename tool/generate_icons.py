"""Draws the HappySpin app icon and writes it for iOS, Android and the web.

Run from the repository root:
    python3 -m pip install cairosvg pillow
    python3 tool/generate_icons.py
"""

import io
import json
import math
from pathlib import Path

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent

# The "Festif" palette from lib/src/app_theme.dart.
SEGMENTS = [
    "#FF7A59", "#FFC145", "#5BC0BE", "#6C63FF",
    "#EF476F", "#06D6A0", "#118AB2", "#F78C6B",
]
POINTER = "#D7263D"
BACKGROUND_TOP = "#3B3270"
BACKGROUND_BOTTOM = "#1E1A3D"
BACKGROUND_SOLID = "#2B2556"


def wheel(cx, cy, r):
    """The wheel, its pegs, its hub and the pointer, centered on (cx, cy)."""
    parts = [
        f'<circle cx="{cx}" cy="{cy + r * 0.05}" r="{r * 1.02}" fill="#000" opacity="0.28" filter="url(#blur)"/>'
    ]
    n = len(SEGMENTS)
    for i, color in enumerate(SEGMENTS):
        # Offset by half a segment so the pointer points into the middle of one.
        a0 = -math.pi / 2 + (i - 0.5) * 2 * math.pi / n
        a1 = a0 + 2 * math.pi / n
        x0, y0 = cx + r * math.cos(a0), cy + r * math.sin(a0)
        x1, y1 = cx + r * math.cos(a1), cy + r * math.sin(a1)
        parts.append(
            f'<path d="M{cx},{cy} L{x0:.2f},{y0:.2f} A{r},{r} 0 0 1 {x1:.2f},{y1:.2f} Z" '
            f'fill="{color}" stroke="#FFFFFF" stroke-width="{r * 0.018:.2f}" stroke-linejoin="round"/>'
        )
    # A soft light from the top left, like the app's polished look.
    parts.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#shine)"/>')
    parts.append(
        f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="#FFFFFF" stroke-width="{r * 0.07:.2f}"/>'
    )
    peg_r = r * 0.045
    for i in range(n):
        a = -math.pi / 2 + i * 2 * math.pi / n
        px, py = cx + (r - r * 0.13) * math.cos(a), cy + (r - r * 0.13) * math.sin(a)
        parts.append(f'<circle cx="{px:.2f}" cy="{py + peg_r * 0.25:.2f}" r="{peg_r:.2f}" fill="#000" opacity="0.25"/>')
        parts.append(f'<circle cx="{px:.2f}" cy="{py:.2f}" r="{peg_r:.2f}" fill="#F5F5F5"/>')
    hub = r * 0.17
    parts.append(f'<circle cx="{cx}" cy="{cy + hub * 0.12}" r="{hub}" fill="#000" opacity="0.25"/>')
    parts.append(f'<circle cx="{cx}" cy="{cy}" r="{hub}" fill="url(#hub)" stroke="#FFFFFF" stroke-width="{r * 0.025:.2f}"/>')

    # The pointer: an arrowhead with a rounded top, sides curving in to a tip
    # that bites into the wheel.
    w = r * 0.42
    top = cy - r - r * 0.24
    tip = cy - r + r * 0.24
    left, right = cx - w / 2, cx + w / 2
    c = w * 0.16
    mid = top + (tip - top) * 0.55
    path = (
        f"M{cx},{tip} Q{left},{mid} {left},{top + c} Q{left},{top} {left + c},{top} "
        f"L{right - c},{top} Q{right},{top} {right},{top + c} Q{right},{mid} {cx},{tip} Z"
    )
    parts.append(f'<path d="{path}" fill="#000" opacity="0.3" transform="translate(0 {r * 0.03:.2f})" filter="url(#blur)"/>')
    parts.append(
        f'<path d="{path}" fill="url(#pointer)" stroke="#FFFFFF" stroke-width="{r * 0.03:.2f}" stroke-linejoin="round"/>'
    )
    screw_y = top + w / 2
    parts.append(f'<circle cx="{cx}" cy="{screw_y}" r="{w * 0.15:.2f}" fill="url(#screw)" stroke="#8C1726" stroke-width="{r * 0.008:.2f}"/>')
    return "\n".join(parts)


def svg(background, scale=1.0, rounded=False, size=1024):
    """The icon on a [size] canvas; [scale] shrinks the drawing into safe zones."""
    r = 360 * scale
    cx, cy = size / 2, size / 2 + 52 * scale
    defs = f"""
<defs>
  <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="{BACKGROUND_TOP}"/>
    <stop offset="1" stop-color="{BACKGROUND_BOTTOM}"/>
  </linearGradient>
  <radialGradient id="glow" cx="0.5" cy="0.55" r="0.5">
    <stop offset="0" stop-color="#8F7FFF" stop-opacity="0.35"/>
    <stop offset="1" stop-color="#8F7FFF" stop-opacity="0"/>
  </radialGradient>
  <radialGradient id="shine" cx="0.3" cy="0.25" r="0.9">
    <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.28"/>
    <stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0"/>
    <stop offset="1" stop-color="#000000" stop-opacity="0.18"/>
  </radialGradient>
  <radialGradient id="hub" cx="0.35" cy="0.3" r="0.8">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="1" stop-color="#E4E0F2"/>
  </radialGradient>
  <linearGradient id="pointer" x1="0" y1="0" x2="1" y2="1">
    <stop offset="0" stop-color="#E7707F"/>
    <stop offset="0.45" stop-color="{POINTER}"/>
    <stop offset="1" stop-color="#961A2B"/>
  </linearGradient>
  <radialGradient id="screw" cx="0.3" cy="0.3" r="0.8">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="0.6" stop-color="#F2F2F2"/>
    <stop offset="1" stop-color="#C9A0A6"/>
  </radialGradient>
  <filter id="blur" x="-20%" y="-20%" width="140%" height="140%">
    <feGaussianBlur stdDeviation="{14 * scale:.1f}"/>
  </filter>
</defs>"""
    body = []
    if background:
        radius = size * 0.2237 if rounded else 0
        body.append(f'<rect width="{size}" height="{size}" rx="{radius}" fill="url(#bg)"/>')
        body.append(f'<circle cx="{cx}" cy="{cy}" r="{r * 1.45}" fill="url(#glow)"/>')
    body.append(wheel(cx, cy, r))
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
        f'viewBox="0 0 {size} {size}">{defs}\n' + "\n".join(body) + "\n</svg>\n"
    )


def render(source, px, opaque=False):
    png = cairosvg.svg2png(bytestring=source.encode(), output_width=px, output_height=px)
    image = Image.open(io.BytesIO(png)).convert("RGBA")
    if opaque:
        flat = Image.new("RGB", image.size, BACKGROUND_SOLID)
        flat.paste(image, mask=image.split()[3])
        return flat
    return image


def save(source, path, px, opaque=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    render(source, px, opaque).save(path, optimize=True)


def main():
    full = svg(background=True)
    rounded = svg(background=True, rounded=True)
    # Android adaptive icons crop to the inner 72 of 108 dp; the web's maskable
    # icons keep a circle of 80%. Shrink the drawing to stay inside both.
    adaptive = svg(background=False, scale=0.74)
    maskable = svg(background=True, scale=0.92)
    bare = svg(background=False, scale=1.18)

    (ROOT / "assets/icon").mkdir(parents=True, exist_ok=True)
    (ROOT / "assets/icon/app_icon.svg").write_text(full)
    (ROOT / "assets/icon/app_icon_foreground.svg").write_text(adaptive)

    # iOS: square, opaque, the system rounds the corners.
    ios = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((ios / "Contents.json").read_text())
    for entry in contents["images"]:
        px = round(float(entry["size"].split("x")[0]) * int(entry["scale"][0]))
        save(full, ios / entry["filename"], px, opaque=True)

    # Android: legacy icon, plus an adaptive one from Android 8.
    res = ROOT / "android/app/src/main/res"
    for density, factor in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
        save(rounded, res / f"mipmap-{density}/ic_launcher.png", round(48 * factor))
        save(adaptive, res / f"mipmap-{density}/ic_launcher_foreground.png", round(108 * factor))

    # Web: favicon, PWA icons and their maskable variants.
    web = ROOT / "web"
    save(bare, web / "favicon.png", 64)
    save(rounded, web / "icons/Icon-192.png", 192)
    save(rounded, web / "icons/Icon-512.png", 512)
    save(maskable, web / "icons/Icon-maskable-192.png", 192, opaque=True)
    save(maskable, web / "icons/Icon-maskable-512.png", 512, opaque=True)
    save(full, web / "icons/apple-touch-icon.png", 180, opaque=True)


if __name__ == "__main__":
    main()
