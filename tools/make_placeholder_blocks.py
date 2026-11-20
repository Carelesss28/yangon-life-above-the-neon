"""Grey isometric placeholder blocks for buildings whose art isn't ready (or was rejected).

Each block follows the framework canvas formula exactly (section 3): width (W + D) x 16,
height (W + D) x 8 + H, anchor on the bottom row at x = W x 16. Writes
assets/placeholders/blocks/<name>/base.png + info.json, which build_campus_data.py picks up.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets" / "placeholders" / "blocks"

# name: (W, D, H px)  — footprints match the campus layout so doors and paths still line up
BLOCKS = {
    "college_wing_north": (4, 31, 200),
    "college_wing_south_a": (4, 13.4, 200),
    "college_wing_south_b": (4, 14.4, 200),
    "college_wing_west": (4, 19.6, 200),
    "college_wing_east": (4, 19.8, 200),
    "main_gate_a": (1, 10.45, 72),
    "main_gate_b": (1, 11.4, 72),
    "main_hall": (12.2, 15.5, 140),
}

TOP = (150, 152, 160, 255)
LEFT = (122, 124, 134, 255)
RIGHT = (92, 94, 106, 255)
LINE = (52, 50, 70, 255)
STRIP = (112, 237, 245, 255)


def block(W, D, H):
    w = round((W + D) * 16)
    h = round((W + D) * 8 + H)
    ax = round(W * 16)
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    base = h - 1

    def P(x, y, z):  # map corner (x along W from back, y along D) -> image pixel
        return (ax + (x - W) * 16 - (y - D) * 16, base + (x - W) * 8 + (y - D) * 8 - z)

    top = [P(0, 0, H), P(W, 0, H), P(W, D, H), P(0, D, H)]
    left = [P(0, D, 0), P(W, D, 0), P(W, D, H), P(0, D, H)]
    right = [P(W, 0, 0), P(W, D, 0), P(W, D, H), P(W, 0, H)]
    d.polygon(left, fill=LEFT)
    d.polygon(right, fill=RIGHT)
    d.polygon(top, fill=TOP)
    for z in range(48, int(H) - 8, 48):  # storey lines
        d.line([P(0, D, z), P(W, D, z)], fill=LINE)
        d.line([P(W, 0, z), P(W, D, z)], fill=LINE)
    d.line([P(0, D, H - 2), P(W, D, H - 2)], fill=STRIP)  # light strip under the roof edge
    d.line([P(W, 0, H - 2), P(W, D, H - 2)], fill=STRIP)
    for poly in (left, right, top):
        d.line(poly + [poly[0]], fill=LINE)
    return img, [ax, base]


def main():
    for name, (W, D, H) in BLOCKS.items():
        img, anchor = block(W, D, H)
        d = OUT / name
        d.mkdir(parents=True, exist_ok=True)
        img.save(d / "base.png")
        info = {"name": name, "kind": "building", "size": list(img.size), "anchor": anchor,
                "footprint_tiles": [W, D], "placeholder": True}
        (d / "info.json").write_text(json.dumps(info, indent=2))
        print(f"{name:22s} {img.size} anchor={anchor} footprint={W}x{D}")


if __name__ == "__main__":
    main()
