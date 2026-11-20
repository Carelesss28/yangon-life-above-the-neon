"""Draw the first three campus tiles directly at native resolution.

No generated-image inputs, resizing, antialiasing, or palette modification.
Run from any directory: python tools/art/build_campus_test_tiles.py
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'assets' / 'tiles'
PALETTE = list(Image.open(ROOT / 'assets' / 'palette.png').convert('RGBA').getdata())
assert len(PALETTE) == 56, 'Requires the locked 56-color palette'


def inside(x, y):
    half_width = 2 * (min(y, 15-y) + 1)
    return 16-half_width <= x < 16+half_width


def lawn(variant):
    image = Image.new('RGBA', (32, 16), (0, 0, 0, 0))
    for y in range(16):
        for x in range(32):
            if inside(x, y):
                image.putpixel((x, y), PALETTE[8])
    # Short paired clusters, with no dark boundary outlining the tile.
    clusters = {
        1: [(12, 3), (20, 5), (7, 8), (16, 10), (24, 9), (12, 12)],
        2: [(17, 3), (10, 5), (23, 7), (14, 8), (6, 10), (19, 12)],
    }
    for i, (x, y) in enumerate(clusters[variant]):
        color = PALETTE[3] if i % 3 else PALETTE[21]
        for px, py in [(x, y), (x+1, y)]:
            if inside(px, py):
                image.putpixel((px, py), color)
    return image


def stonepath():
    image = Image.new('RGBA', (32, 16), (0, 0, 0, 0))
    # Integer world coordinates: joints follow both 2:1 ground axes.
    for y in range(16):
        for x in range(32):
            if not inside(x, y):
                continue
            u = (x-16) + 2*y
            v = -(x-16) + 2*y
            a, b = u % 16, v % 16
            joint = a < 2 or b < 2
            edge = a in (2, 3) or b in (2, 3)
            index = 6 if joint else 14 if edge else 9
            image.putpixel((x, y), PALETTE[index])
    return image


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    tiles = {'tile_lawn_01': lawn(1), 'tile_lawn_02': lawn(2),
             'tile_stonepath_01': stonepath()}
    report = []
    for name, image in tiles.items():
        path = DEST / f'{name}.png'
        if path.exists():
            raise FileExistsError(f'Refusing to overwrite {path}')
        image.save(path)
        markers = Image.new('RGBA', image.size, (0, 0, 0, 0))
        markers.putpixel((16, 15), (255, 0, 0, 255))
        markers.save(DEST / f'{name}_markers.png')
        reopened = Image.open(path)
        colors = set(reopened.getdata())
        assert reopened.size == (32, 16) and reopened.mode == 'RGBA'
        assert {c[3] for c in colors} == {0, 255}
        assert all(c in PALETTE[:36] for c in colors if c[3])
        assert all(bool(reopened.getpixel((x, y))[3]) == inside(x, y)
                   for y in range(16) for x in range(32))
        report.append({'name': name, 'size': [32, 16], 'footprint': [1, 1],
                       'anchor': [16, 15], 'opaque_colors': len(colors)-1,
                       'native_1x': True, 'palette_verified': True})
    (DEST / 'campus_test_tiles.json').write_text(json.dumps({
        'workflow': 'Direct native-grid procedural drawing with Pillow; no resampling.',
        'godot_import_tested': False,
        'notes': 'Early test tiles. No glow required. Marker red is metadata, exempt from art palette.',
        'tiles': report}, indent=2), encoding='utf-8')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
