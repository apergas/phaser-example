"""
Builds the game's LPC textures from the raw sources in ./sources.

  python3 build_assets.py

Outputs (into rpg/public/assets/lpc/):
  hero-walk.png / hero-idle.png   character sheets composed from layers, clothes recoloured
  forest.png + forest.json         Phaser JSON-hash atlas with trees (pivot = trunk base) and decor
  ground.png                       grass tile(s) for the tilemap (32x32 each, in a row)

Requires Pillow. Licences and authors: see CREDITS.md next to the outputs.
"""

from pathlib import Path
import json

from PIL import Image

ROOT = Path(__file__).parent
SOURCES = ROOT / "sources"
OUT = ROOT.parent.parent / "rpg" / "public" / "assets" / "lpc"

# --- Character -------------------------------------------------------------------------------

# Bottom to top, same z-order as the Universal LPC generator (zPos).
CHARACTER_LAYERS = [
    "body_bodies_male",
    "feet_boots_basic_male",
    "legs_pants_male",
    "torso_clothes_longsleeve_longsleeve_male",
    "head_heads_human_male",
    "hair_plain_adult",
]

# Clothes ship in a neutral ramp meant to be recoloured. Each ramp is dark -> light.
CLOTH_RAMP = [(77, 74, 93), (149, 128, 128), (196, 181, 159), (229, 230, 199), (255, 255, 255)]
HAIR_RAMP = [(106, 17, 8), (164, 38, 0), (191, 64, 0), (229, 86, 0), (255, 138, 0)]
RECOLOURS = {
    "torso_clothes_longsleeve_longsleeve_male": (CLOTH_RAMP, [(30, 50, 35), (46, 82, 50), (64, 112, 62), (88, 140, 76), (118, 168, 96)]),
    "legs_pants_male": (CLOTH_RAMP, [(48, 34, 30), (78, 54, 40), (104, 74, 52), (132, 98, 68), (160, 124, 88)]),
    "feet_boots_basic_male": (CLOTH_RAMP, [(30, 20, 18), (52, 36, 28), (76, 52, 36), (100, 70, 48), (124, 90, 60)]),
    "hair_plain_adult": (HAIR_RAMP, [(52, 32, 22), (74, 46, 30), (96, 62, 40), (118, 80, 52), (142, 100, 66)]),
}


def recolour(image: Image.Image, source: list, target: list) -> Image.Image:
    mapping = dict(zip(source, target))
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a and (r, g, b) in mapping:
                pixels[x, y] = mapping[(r, g, b)] + (a,)
    return image


def build_character() -> None:
    for animation in ("walk", "idle"):
        sheet = None
        for layer in CHARACTER_LAYERS:
            image = Image.open(SOURCES / "character" / f"{layer}__{animation}.png").convert("RGBA")
            if layer in RECOLOURS:
                image = recolour(image, *RECOLOURS[layer])
            sheet = image if sheet is None else Image.alpha_composite(sheet, image)
        sheet.save(OUT / f"hero-{animation}.png")


# --- Forest atlas ----------------------------------------------------------------------------

# Bounding boxes (x0, y0, x1, y1) of individual trees in trees-green.png, shadows included.
TREES = {
    "tree-slim": (64, 96, 128, 224),
    "tree-round": (128, 104, 223, 222),
    "tree-wide": (231, 104, 314, 210),
    "tree-broad": (320, 102, 416, 224),
    "tree-twisted": (66, 230, 154, 350),
    "tree-branches": (264, 224, 371, 352),
    "tree-leaning": (384, 224, 478, 351),
    "tree-lumpy": (485, 226, 574, 352),
    "tree-pine": (64, 356, 127, 505),
    "tree-dome": (129, 352, 223, 489),
    "tree-oak": (418, 352, 543, 503),
    "tree-dense": (556, 356, 660, 494),
    "tree-old": (0, 535, 150, 704),
    "tree-big": (161, 530, 288, 695),
}

# 32x32 cells of terrain_atlas.png (column, row).
DECOR = {
    "decor-tall-grass": (26, 30),
    "decor-mushrooms": (27, 28),
    "decor-rock": (29, 24),
    "decor-leaves": (12, 18),
}
GROUND_TILES = [(1, 23)]
CELL = 32


def trunk_base(image: Image.Image, rows: int = 8) -> tuple:
    """
    Base of the trunk: y = lowest row with fully opaque pixels (shadows are translucent),
    x = median of the opaque pixels in the lowest `rows` such rows, so stray roots or grass
    on one side do not drag it off-centre.
    """
    alpha = image.split()[3].load()
    base_y, xs = None, []
    for y in range(image.height - 1, -1, -1):
        row = [x for x in range(image.width) if alpha[x, y] == 255]
        if len(row) < 3:
            continue
        base_y = base_y or y + 1
        xs.extend(row)
        rows -= 1
        if rows == 0:
            break
    if base_y is None:
        return image.width / 2, image.height
    xs.sort()
    return xs[len(xs) // 2], base_y


def pack(frames: dict, width: int = 1024, padding: int = 2) -> tuple:
    """Shelf packing; returns the atlas image and each frame's position."""
    x = y = shelf = 0
    positions = {}
    for name, image in sorted(frames.items(), key=lambda item: -item[1].height):
        if x + image.width > width:
            x, y, shelf = 0, y + shelf + padding, 0
        positions[name] = (x, y)
        x += image.width + padding
        shelf = max(shelf, image.height)
    atlas = Image.new("RGBA", (width, y + shelf))
    for name, (fx, fy) in positions.items():
        atlas.alpha_composite(frames[name], (fx, fy))
    return atlas, positions


def build_forest() -> None:
    trees_sheet = Image.open(SOURCES / "terrain" / "trees-green.png").convert("RGBA")
    terrain = Image.open(SOURCES / "terrain" / "terrain_atlas.png").convert("RGBA")

    frames, pivots = {}, {}
    for name, box in TREES.items():
        image = trees_sheet.crop(box)
        frames[name] = image
        base_x, base_y = trunk_base(image)
        pivots[name] = {"x": round(base_x / image.width, 4), "y": round(base_y / image.height, 4)}
    for name, (column, row) in DECOR.items():
        image = terrain.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))
        frames[name] = image.crop(image.getbbox())
        pivots[name] = {"x": 0.5, "y": 1}

    atlas, positions = pack(frames)
    atlas.save(OUT / "forest.png")
    data = {
        "frames": {
            name: {
                "frame": {"x": x, "y": y, "w": frames[name].width, "h": frames[name].height},
                "rotated": False,
                "trimmed": False,
                "spriteSourceSize": {"x": 0, "y": 0, "w": frames[name].width, "h": frames[name].height},
                "sourceSize": {"w": frames[name].width, "h": frames[name].height},
                "pivot": pivots[name],
            }
            for name, (x, y) in positions.items()
        },
        "meta": {"image": "forest.png", "size": {"w": atlas.width, "h": atlas.height}, "scale": "1"},
    }
    (OUT / "forest.json").write_text(json.dumps(data, indent=1))

    ground = Image.new("RGBA", (CELL * len(GROUND_TILES), CELL))
    for index, (column, row) in enumerate(GROUND_TILES):
        ground.alpha_composite(terrain.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL)), (index * CELL, 0))
    ground.save(OUT / "ground.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    build_character()
    build_forest()
    print(f"Assets written to {OUT}")
