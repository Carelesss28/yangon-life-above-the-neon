"""Turn the cleaned campus pieces into game data.

- Copies the ground tiles from Downloads/mecharpg and slices the 4x4 slabs into 32x16 tiles.
- Writes game/data/pieces.json: for every piece its texture, glow, anchor and footprint.
  Anchors and footprints come from marker pixels when the artist adds them; until then they use
  the front-corner x positions below, read by eye from the angle-corrected art.
Run after tools/process_ai_art.py:  python tools/build_campus_data.py
"""
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
INC = ROOT / "assets" / "_incoming"
TILES = INC / "tiles"
RAW = Path.home() / "Downloads" / "mecharpg"
DATA = ROOT / "game" / "data"

# x of the front ground corner (where the two walls meet), read from the corrected images
FRONT_X = {
    "dept_pilot": 240,
}
BLOCKS = ROOT / "assets" / "placeholders" / "blocks"


def lowest_in_column(alpha, x):
    col = np.nonzero(alpha[:, max(0, x - 1): x + 2].any(1))[0]
    return int(col.max())


def piece_entry(name):
    d = INC / name
    info = json.loads((d / "info.json").read_text())
    img = np.asarray(Image.open(d / "base.png"))
    alpha = img[..., 3] > 0
    w, h = info["size"]
    kind = info["kind"]
    if name in FRONT_X:
        ax = FRONT_X[name]
        anchor = [ax, lowest_in_column(alpha, ax)]
        fp = [round(ax / 16, 2), round((w - ax) / 16, 2)]
    elif kind == "interior":
        ax = w // 2
        anchor = [ax, lowest_in_column(alpha, ax)]
        fp = [round(ax / 16, 2), round((w - ax) / 16, 2)]
    else:
        anchor = info["anchor"]
        fp = info["footprint_tiles"]
    return {
        "kind": kind,
        "texture": f"res://assets/_incoming/{name}/base.png",
        "glow": f"res://assets/_incoming/{name}/glow.png" if (d / "glow.png").exists() else "",
        "size": [w, h],
        "anchor": anchor,
        "footprint": fp,
    }


def slice_slab(name, prefix):
    """Cut the top diamond of a 4x4 slab (128 px wide) into 16 isometric 32x16 tiles."""
    img = Image.open(INC / name / "base.png").convert("RGBA")
    a = np.asarray(img)
    top = int(np.nonzero(a[..., 3].any(1))[0].min())
    out = []
    yy, xx = np.mgrid[0:16, 0:32]
    diamond = (np.abs(xx - 15.5) / 16 + np.abs(yy - 7.5) / 8) <= 1.0
    for i in range(4):
        for j in range(4):
            cx = 64 + (i - j) * 16
            cy = top + (i + j + 1) * 8
            tile = a[cy - 8: cy + 8, cx - 16: cx + 16].copy()
            if tile.shape[:2] != (16, 32):
                continue
            tile[..., 3] = np.where(diamond & (tile[..., 3] > 0), 255, 0)
            if (tile[..., 3] > 0).mean() < 0.45:
                continue
            p = TILES / f"{prefix}_{i}{j}.png"
            Image.fromarray(tile, "RGBA").save(p)
            out.append(f"res://assets/_incoming/tiles/{p.name}")
    return out


def main():
    TILES.mkdir(parents=True, exist_ok=True)
    DATA.mkdir(parents=True, exist_ok=True)
    tiles = {}
    for stem in ("tile_lawn_01", "tile_lawn_02", "tile_stonepath_01"):
        if (RAW / f"{stem}.png").exists():
            shutil.copy2(RAW / f"{stem}.png", TILES / f"{stem}.png")
    tiles["lawn"] = [f"res://assets/_incoming/tiles/{s}.png" for s in ("tile_lawn_01", "tile_lawn_02")]
    tiles["path"] = ["res://assets/_incoming/tiles/tile_stonepath_01.png"]
    tiles["plaza"] = slice_slab("brick_plaza", "brick_plaza")
    tiles["paving"] = slice_slab("stonepath_slab", "stone_slab")

    pieces = {}
    for d in sorted(p for p in INC.iterdir() if (p / "info.json").exists()):
        if json.loads((d / "info.json").read_text())["kind"] == "slab":
            continue
        pieces[d.name] = piece_entry(d.name)
    # grey placeholder blocks (tools/make_placeholder_blocks.py) stand in for missing buildings
    if BLOCKS.exists():
        for d in sorted(p for p in BLOCKS.iterdir() if (p / "info.json").exists()):
            info = json.loads((d / "info.json").read_text())
            pieces[d.name] = {
                "kind": "building", "texture": f"res://assets/placeholders/blocks/{d.name}/base.png", "glow": "",
                "size": info["size"], "anchor": info["anchor"], "footprint": info["footprint_tiles"],
            }
    (DATA / "pieces.json").write_text(json.dumps({"tiles": tiles, "pieces": pieces}, indent=1))
    print(f"{len(pieces)} pieces, tiles: " + ", ".join(f"{k}={len(v)}" for k, v in tiles.items()))
    for n, p in pieces.items():
        print(f"  {n:20s} {p['kind']:9s} anchor={p['anchor']} footprint={p['footprint']}")


if __name__ == "__main__":
    main()
