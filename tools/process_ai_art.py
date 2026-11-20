"""Clean up AI-generated campus art (framework.md section 17, steps 1-5).

Raw images come from Downloads/mecharpg. For each piece in PIECES this:
  1. copies the raw image + prompt into art_source/<piece>/
  2. removes the flat green background (and green spill on edges)
  3. scales the object to its game size (target width or height in px)
  4. maps colours to assets/palette.png; neon colours only for bright, saturated pixels
  5. writes a draft glow mask from the neon pixels, finds the anchor, and writes info.txt
Results go to assets/_incoming/<piece>/.  Run:  python tools/process_ai_art.py
"""
import json
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RAW = Path.home() / "Downloads" / "mecharpg"
PALETTE = ROOT / "assets" / "palette.png"
OUT = ROOT / "assets" / "_incoming"
SRC = ROOT / "art_source"

N_BASE = 36  # palette: first 36 world colours, then neon (framework section 0)

# piece -> (raw file stem, kind, size rule).  Buildings are sized so one storey is about 48 px
# (framework section 1), measured on each image; AI proportions differ, so footprints follow the art.
# Colonial-style pieces (gate, dorm wings, heritage hall) were removed 2026-11-18: the game is
# modern cyberpunk only (framework section 0b). Their files are in art_source/_rejected_colonial/.
PIECES = {
    "dept_pilot":         ("dept_pilot_20261118_01", "building", {"w": 608, "slopes": [0.46, 0.33]}),
    "classroom":          ("classroom_20261118_01", "interior", {"w": 288}),
    "sim_pod_room":       ("sim_pod_room_20261118_01", "interior", {"w": 256}),
    "dorm_room":          ("dorm_room_20261118_01", "interior", {"w": 144}),
    "common_room":        ("common_room_20261118_01", "interior", {"w": 288}),
    "rain_tree":          ("rain_tree_20261118_01", "prop", {"w": 288, "fp": [2, 2]}),
    "padauk_tree":        ("padauk_tree_20261118_02", "prop", {"w": 176, "fp": [1, 1]}),
    "hedge_planter":      ("hedge_planter_20261118_01", "prop", {"w": 96, "fp": [4, 2]}),
    "flower_bed":         ("tile_flower_bed_01_20261118_01", "prop", {"w": 96, "fp": [3, 3]}),
    "hedge_edge":         ("tile_hedge_edge_01_20261118_01", "prop", {"w": 80, "fp": [3, 2]}),
    "holo_crest":         ("prop_holo_crest_20261118_01", "prop", {"h": 72, "fp": [1, 1]}),
    "heritage_lamp_post": ("heritage_lamp_post_20261118_01", "prop", {"h": 80}),
    "bench":              ("bench_20261118_01", "prop", {"w": 48, "fp": [1, 2]}),
    "mech_statue":        ("mech_statue_20261118_01", "prop", {"h": 160, "fp": [3, 3]}),
    "holo_notice_board":  ("holo_notice_board_20261118_01", "prop", {"h": 56, "fp": [1, 2]}),
    "hover_bike_rack":    ("hover_bike_rack_20261118_01", "prop", {"w": 64, "fp": [1, 3]}),
    "brick_plaza":        ("tile_brick_plaza_01_20261118_01", "slab", {"tiles": 4}),
    "stonepath_slab":     ("tile_stonepath_02_20261118_01", "slab", {"tiles": 4}),
}


def srgb_to_lab(rgb):
    c = rgb.astype(np.float64) / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def load_palette():
    p = np.asarray(Image.open(PALETTE).convert("RGB"))[0]
    return p, srgb_to_lab(p)


def key_green(a):
    """RGB uint8 -> RGBA float with the flat green background removed and edge spill cleaned."""
    rgb = a[..., :3].astype(np.float64)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    greenness = g - np.maximum(r, b)
    bg = (greenness > 70) & (g > 140)
    alpha = np.where(bg, 0.0, 1.0)
    # partial spill: strongly green-tinted pixels next to background lose their green cast
    spill = (~bg) & (greenness > 25)
    rgb[..., 1] = np.where(spill, np.maximum(r, b) + 10, g)
    return np.dstack([rgb, alpha])


def correct_angle(rgba, k_left, k_right):
    """Map a building drawn from a flatter camera back to exact 2:1.

    k_left / k_right are the measured slopes (px down per px across) of the base edges left and
    right of the front corner. The affine map x' = a*x, y' = y + c*x with a = k_left + k_right and
    c = (k_right - k_left) / 2 sends both ground directions to slope 0.5 and keeps verticals vertical,
    so walls, roofs and windows along either axis all come out on the 2:1 grid.
    """
    a = k_left + k_right
    c = (k_right - k_left) / 2
    h, w = rgba.shape[:2]
    shift = -min(0.0, c * w)
    W, H = int(np.ceil(a * w)), int(np.ceil(h + abs(c) * w))
    pre = rgba.copy()
    pre[..., :3] *= pre[..., 3:4]
    chans = []
    for i in range(4):
        band = Image.fromarray((pre[..., i] * (1 if i < 3 else 255)).astype(np.float32), "F")
        # output (X, Y) samples input (X / a, Y - shift - c * X / a)
        band = band.transform((W, H), Image.AFFINE, (1 / a, 0, 0, -c / a, 1, -shift), Image.BILINEAR)
        chans.append(np.asarray(band, np.float64))
    out = np.dstack(chans)
    alpha = out[..., 3] / 255.0
    rgb = np.where(alpha[..., None] > 0, out[..., :3] / np.maximum(alpha[..., None], 1e-6), 0)
    return np.dstack([rgb, alpha])


def crop(rgba):
    ys, xs = np.nonzero(rgba[..., 3] > 0.5)
    return rgba[ys.min(): ys.max() + 1, xs.min(): xs.max() + 1]


def resize(rgba, w, h):
    pre = rgba.copy()
    pre[..., :3] *= pre[..., 3:4]
    im = Image.fromarray(np.clip(pre * [1, 1, 1, 255], 0, 255).astype(np.uint8), "RGBA")
    # premultiplied channels stored; resample each channel with a box filter (area average)
    chans = [np.asarray(Image.fromarray(np.asarray(im)[..., i]).resize((w, h), Image.BOX), np.float64) for i in range(4)]
    out = np.dstack(chans)
    a = out[..., 3] / 255.0
    rgb = np.where(a[..., None] > 0, out[..., :3] / np.maximum(a[..., None], 1e-6), 0)
    return np.dstack([rgb, a])


def quantize(rgba, pal, pal_lab):
    rgb = np.clip(rgba[..., :3], 0, 255)
    alpha = rgba[..., 3] >= 0.5
    flat = rgb.reshape(-1, 3)
    lab = srgb_to_lab(flat)
    mx, mn = flat.max(1), flat.min(1)
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1), 0)
    bright = mx / 255.0
    # hue in [0, 1): reds and oranges (brick, roof tiles) need to be much brighter to count as neon
    r, g, b = flat[:, 0], flat[:, 1], flat[:, 2]
    hue = np.where(mx == r, ((g - b) / np.maximum(mx - mn, 1)) % 6, np.where(mx == g, (b - r) / np.maximum(mx - mn, 1) + 2, (r - g) / np.maximum(mx - mn, 1) + 4)) / 6
    warm = (hue < 0.11) | (hue > 0.95)
    neon_ok = (sat > 0.55) & (bright > 0.75) & (~warm | (bright > 0.93))
    d = ((lab[:, None, :] - pal_lab[None, :, :]) ** 2).sum(-1)
    d[~neon_ok, N_BASE:] = np.inf  # world pixels may not use neon colours
    idx = d.argmin(1).reshape(rgb.shape[:2])
    out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    out[..., :3] = pal[idx]
    out[..., 3] = np.where(alpha, 255, 0)
    glow = np.zeros_like(out)
    neon = alpha & (idx >= N_BASE)
    glow[neon] = out[neon]
    return out, glow, int(neon.sum())


def anchor_of(img):
    a = img[..., 3] > 0
    ys = np.nonzero(a.any(1))[0]
    bottom = ys.max()
    xs = np.nonzero(a[max(bottom - 2, 0): bottom + 1].any(0))[0]
    return int(round(xs.mean())), int(bottom)


def base_corners(img):
    """Left and right ground corners, found by following the bottom outline out from the front corner.

    Along each base edge the outline climbs smoothly (about 1 px up per 2 px across). Where a roof
    eave or overhang takes over, the outline jumps upward, so the walk stops there.
    """
    a = img[..., 3] > 0
    h, w = a.shape
    has = a.any(0)
    bottom = np.where(has, h - 1 - np.argmax(a[::-1], axis=0), -1)
    ax, _ = anchor_of(img)

    ay = bottom[ax]

    def walk(step, k):
        """Follow a base line of slope k from the anchor. Returns (good columns, corner)."""
        x, last, gap, good = ax, ax, 0, 0
        while 0 <= x + step < w:
            x += step
            y = int(round(ay - abs(x - ax) * k))
            if y < 0:
                break
            # on the base edge: sprite at the line, nothing a few pixels below it.
            # Stairs, planters and lamps in front break this for a while, so allow longer gaps.
            if a[max(y - 3, 0): y + 2, x].any() and not a[y + 4: y + 9, x].any():
                last, gap, good = x, 0, good + 1
            else:
                gap += 1
                if gap > 48:
                    break
        return good, (last, int(round(ay - abs(last - ax) * k)))

    def best(step):
        # AI art drifts off the exact 2:1 angle: try nearby slopes, keep the one that fits the base best
        return max((walk(step, k) for k in np.arange(0.40, 0.605, 0.01)), key=lambda r: r[0])[1]

    return best(-1), best(1)


def process(name, stem, kind, rule, pal, pal_lab):
    raw_png = RAW / f"{stem}.png"
    if not raw_png.exists():
        return None
    src_dir = SRC / name
    src_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(raw_png, src_dir / "raw.png")
    prompt = RAW / f"{stem}_prompt.txt"
    if prompt.exists():
        shutil.copy2(prompt, src_dir / "prompt.txt")

    rgba = crop(key_green(np.asarray(Image.open(raw_png).convert("RGB"))))
    h0, w0 = rgba.shape[:2]
    if kind == "slab":
        s = rule["tiles"] * 32 / w0
    elif "w" in rule:
        s = rule["w"] / w0
    else:
        s = rule["h"] / h0
    if "slopes" in rule:
        rgba = crop(correct_angle(rgba, *rule["slopes"]))
    w, h = max(1, round(rgba.shape[1] * s)), max(1, round(rgba.shape[0] * s))
    small = resize(rgba, w, h)
    img, glow, neon_px = quantize(small, pal, pal_lab)

    out_dir = OUT / name
    out_dir.mkdir(parents=True, exist_ok=True)
    Image.fromarray(img, "RGBA").save(out_dir / "base.png")
    if neon_px:
        Image.fromarray(glow, "RGBA").save(out_dir / "glow.png")
    elif (out_dir / "glow.png").exists():
        (out_dir / "glow.png").unlink()
    ax, ay = anchor_of(img)
    (lx, ly), (rx, ry) = base_corners(img)
    if kind in ("building", "interior", "slab"):
        fp = [round((ax - lx) / 16, 1), round((rx - ax) / 16, 1)]
    else:  # props: canopies and signs overhang, so the ground footprint is set by hand
        fp = rule.get("fp", [1, 1])
    info = {
        "name": name, "kind": kind, "raw": raw_png.name, "size": [w, h],
        "anchor": [ax, ay],
        # ground corners in image pixels: left, front (= anchor) and right; the back corner is left + right - front
        "base_left": [lx, ly], "base_right": [rx, ry],
        "footprint_tiles": fp,
        "glow_pixels": neon_px,
        "todo": ["roof split", "marker pixels", "hand clean-up"] if kind == "building" else ["marker pixels", "hand clean-up"],
    }
    (out_dir / "info.json").write_text(json.dumps(info, indent=2))
    return info


def main(only=None):
    pal, pal_lab = load_palette()
    done, missing = [], []
    for name, (stem, kind, rule) in PIECES.items():
        if only and name not in only:
            continue
        info = process(name, stem, kind, rule, pal, pal_lab)
        (done if info else missing).append(name)
        if info:
            print(f"{name:20s} {kind:9s} {info['size'][0]:4d}x{info['size'][1]:<4d} anchor={info['anchor']} "
                  f"footprint={info['footprint_tiles']} L={info['base_left']} R={info['base_right']} glow={info['glow_pixels']}")
    if missing:
        print("missing raw images:", ", ".join(missing))


if __name__ == "__main__":
    main(set(sys.argv[1:]) or None)
