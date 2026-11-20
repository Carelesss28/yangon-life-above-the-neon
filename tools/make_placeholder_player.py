"""Placeholder player sprite sheet until the real character art arrives (framework section 9).

32 x 48 frames. Row 0 faces down-right (front), row 1 faces up-right (back).
Columns: idle, walk 1-4. Mirrored in the engine for the other two directions.
"""
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parents[1] / "assets" / "placeholders" / "player.png"
INK = (33, 27, 40, 255)
SKIN = (233, 190, 150, 255)
SKIN_D = (196, 142, 110, 255)
HAIR = (40, 34, 52, 255)
HAIR_L = (72, 62, 92, 255)
JACKET = (52, 92, 102, 255)
JACKET_L = (82, 128, 132, 255)
STRIP = (112, 237, 245, 255)
PANTS = (52, 50, 72, 255)
SHOE = (230, 226, 214, 255)
BAG = (58, 62, 70, 255)


def rect(im, x, y, w, h, c):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            if 0 <= xx < im.width and 0 <= yy < im.height:
                im.putpixel((xx, yy), c)


def frame(front, step):
    im = Image.new("RGBA", (32, 48))
    f = Image.new("RGBA", (32, 48))
    bob = 1 if step in (2, 4) else 0
    lift_l = 2 if step == 1 else 0
    lift_r = 2 if step == 3 else 0
    swing = {1: 1, 3: -1}.get(step, 0)
    y0 = 46 - bob  # feet line
    parts = [
        (11, y0 - 11, 4, 11 - lift_l, PANTS), (17, y0 - 11, 4, 11 - lift_r, PANTS),   # legs
        (9 - 1, y0 - 23 + swing, 3, 10, JACKET), (21, y0 - 23 - swing, 3, 10, JACKET),  # arms
        (10, y0 - 24, 12, 14, JACKET),                                                    # body
        (10, y0 - 34, 12, 11, SKIN),                                                      # head
    ]
    for x, y, w, h, _ in parts:  # outline pass
        rect(f, x - 1, y - 1, w + 2, h + 2, INK)
    for x, y, w, h, c in parts:
        rect(f, x, y, w, h, c)
    rect(f, 11, y0 - 1 - lift_l, 4, 2, SHOE)
    rect(f, 17, y0 - 1 - lift_r, 4, 2, SHOE)
    rect(f, 10, y0 - 24, 2, 14, JACKET_L)
    rect(f, 10, y0 - 17, 12, 1, STRIP)  # academy light strip
    rect(f, 8, y0 - 14 + swing, 3, 2, SKIN)
    rect(f, 21, y0 - 14 - swing, 3, 2, SKIN)
    hy = y0 - 34
    if front:
        rect(f, 10, hy, 12, 4, HAIR)
        rect(f, 10, hy + 4, 2, 3, HAIR)
        rect(f, 20, hy + 4, 2, 2, HAIR)
        rect(f, 13, hy + 1, 5, 1, HAIR_L)
        rect(f, 15, hy + 6, 1, 2, INK)
        rect(f, 19, hy + 6, 1, 2, INK)
        rect(f, 14, hy + 9, 1, 1, SKIN_D)
        rect(f, 19, hy + 9, 1, 1, SKIN_D)
        rect(f, 15, y0 - 23, 2, 8, JACKET_L)
    else:
        rect(f, 10, hy, 12, 9, HAIR)
        rect(f, 12, hy + 1, 6, 1, HAIR_L)
        rect(f, 11, y0 - 23, 10, 9, BAG)  # backpack
        rect(f, 11, y0 - 23, 10, 1, INK)
    im.alpha_composite(f)
    return im


def main():
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (32 * 5, 48 * 2))
    for row, front in enumerate((True, False)):
        for col in range(5):
            sheet.alpha_composite(frame(front, col), (col * 32, row * 48))
    sheet.save(OUT)
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(OUT.with_name("player_preview_4x.png"))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
