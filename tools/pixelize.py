"""Turn a Blender render (tools/blender_render_topdown.py) into game pixel art.

  python tools/pixelize.py <render.png> <out.png> [ss] --iso [--no-outline] [--master]

- shrinks to 16 px per metre on every axis (x also loses the 1/cos(45) stretch from the render)
- hard alpha (pixels fully opaque or fully transparent)
- colours snapped to assets/palette.png (world colours; neon only for bright saturated pixels)
- a 1 px dark outline around the silhouette (framework section 1, outlines)
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from process_ai_art import load_palette, quantize, resize  # noqa: E402

OUTLINE = (33, 27, 40)


def auto_levels(rgba, top=0.86):
    """Stretch brightness so dark models still read in 3-4 shades (neutral daylight rule)."""
    out = rgba.copy()
    a = out[..., 3] > 0.5
    if not a.any():
        return out
    lum = out[..., :3].max(-1)[a]
    lo, hi = np.percentile(lum, 2), np.percentile(lum, 97)
    if hi - lo < 1:
        return out
    gain = top * 255 / max(hi, 1)
    out[..., :3] = np.clip(out[..., :3] * min(gain, 3.0), 0, 255)
    return out


def fit_palette(rgba, n_world=13, n_neon=6):
    """Palette fitted to one asset: world colours by median cut, plus neon colours per hue band."""
    rgb = np.clip(rgba[..., :3], 0, 255)
    alpha = rgba[..., 3] >= 0.5
    flat = rgb[alpha].reshape(-1, 3)
    mx, mn = flat.max(1), flat.min(1)
    sat = (mx - mn) / np.maximum(mx, 1)
    neon_mask = (sat > 0.5) & (mx > 150)
    world = flat[~neon_mask] if (~neon_mask).sum() > 0 else flat
    wim = Image.fromarray(world.reshape(1, -1, 3).astype(np.uint8), "RGB")
    wq = wim.quantize(colors=n_world, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    cols = [tuple(wq.getpalette()[i * 3: i * 3 + 3]) for i in range(n_world)]
    neon = flat[neon_mask]
    if len(neon):
        r, g, b = neon[:, 0], neon[:, 1], neon[:, 2]
        nmx, nmn = neon.max(1), neon.min(1)
        d = np.maximum(nmx - nmn, 1)
        hue = np.where(nmx == r, ((g - b) / d) % 6, np.where(nmx == g, (b - r) / d + 2, (r - g) / d + 4)) / 6
        bins = (hue * 12).astype(int) % 12
        counts = [(int((bins == k).sum()), k) for k in range(12)]
        for c, k in sorted(counts, reverse=True)[:n_neon]:
            if c >= 12:
                sel = neon[bins == k]
                cols.append(tuple(int(v) for v in np.median(sel[sel.max(1) >= np.percentile(sel.max(1), 50)], 0)))
    pal = np.array(cols, np.float64)
    d = ((rgb.reshape(-1, 1, 3) - pal[None]) ** 2).sum(-1)
    idx = d.argmin(1).reshape(rgb.shape[:2])
    out = np.zeros(rgb.shape[:2] + (4,), np.uint8)
    out[..., :3] = pal[idx].astype(np.uint8)
    out[..., 3] = np.where(alpha, 255, 0)
    return out


def block_mode(img, k):
    """Downscale by k, giving each output pixel the most common colour (and alpha) of its k x k block."""
    h, w = img.shape[0] // k, img.shape[1] // k
    out = np.zeros((h, w, 4), np.uint8)
    key = (img[..., 0].astype(np.int64) << 24) | (img[..., 1].astype(np.int64) << 16) | (img[..., 2].astype(np.int64) << 8) | img[..., 3]
    for y in range(h):
        for x in range(w):
            blk = key[y * k:(y + 1) * k, x * k:(x + 1) * k].ravel()
            opaque = blk[(blk & 255) > 0]
            if len(opaque) * 2 < len(blk):
                continue
            vals, counts = np.unique(opaque, return_counts=True)
            v = int(vals[counts.argmax()])
            out[y, x] = ((v >> 24) & 255, (v >> 16) & 255, (v >> 8) & 255, 255)
    return out


def clean_strays(img, passes=2):
    """Replace single pixels that differ from all 4 neighbours with the most common neighbour colour."""
    img = img.copy()
    for _ in range(passes):
        rgb = img[..., :3].astype(np.int32)
        key = (rgb[..., 0] << 16) | (rgb[..., 1] << 8) | rgb[..., 2]
        opaque = img[..., 3] > 0
        h, w = key.shape
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                if not opaque[y, x]:
                    continue
                n = [key[y - 1, x], key[y + 1, x], key[y, x - 1], key[y, x + 1]]
                no = [opaque[y - 1, x], opaque[y + 1, x], opaque[y, x - 1], opaque[y, x + 1]]
                if not all(no) or key[y, x] in n:
                    continue
                vals, counts = np.unique(n, return_counts=True)
                k = int(vals[counts.argmax()])
                img[y, x, :3] = ((k >> 16) & 255, (k >> 8) & 255, k & 255)
    return img


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src, out = args[0], args[1]
    ss = int(args[2]) if len(args) > 2 else 4
    a = np.asarray(Image.open(src).convert("RGBA")).astype(np.float64)
    rgba = np.dstack([a[..., :3], a[..., 3] / 255.0])
    ys, xs = np.nonzero(rgba[..., 3] > 0.02)
    rgba = rgba[ys.min(): ys.max() + 1, xs.min(): xs.max() + 1]
    h0, w0 = rgba.shape[:2]
    # isometric renders (tools/blender_render_iso.py) are already at the right x scale;
    # the old top-down renders were stretched in x by 1/cos(45)
    xfac = 1.0 if "--iso" in sys.argv else math.cos(math.radians(45))
    w = max(1, round(w0 * xfac / ss))
    h = max(1, round(h0 / ss))
    # work at 4x the game size, then take the most common colour per 4x4 block (keeps edges crisp)
    K = 4
    mid = resize(rgba, w * K, h * K)
    mid = auto_levels(mid)
    if "--master" in sys.argv:
        pal, pal_lab = load_palette()
        qimg, _, _ = quantize(mid, pal, pal_lab)
    else:
        qimg = fit_palette(mid)
    img = block_mode(qimg, K)
    img = clean_strays(img)
    if "--no-outline" not in sys.argv:
        alpha = img[..., 3] > 0
        pad = np.pad(alpha, 1)
        ring = np.zeros_like(pad)
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            ring |= np.roll(np.roll(pad, dy, 0), dx, 1)
        ring &= ~pad
        big = np.zeros(pad.shape + (4,), np.uint8)
        big[1:-1, 1:-1] = img
        big[ring] = (*OUTLINE, 255)
        img = big
    Image.fromarray(img, "RGBA").save(out)
    print(f"{out}: {img.shape[1]} x {img.shape[0]} px")


if __name__ == "__main__":
    main()
