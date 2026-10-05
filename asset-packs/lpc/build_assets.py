"""
Builds the game's LPC textures from the raw sources in ./sources.

  python3 build_assets.py

Outputs (into lib/core/assets/images/lpc/, the copy the Flutter app bundles; mirrored into
shared/assets/lpc/ while the Kotlin Multiplatform apps still exist):
  hero-{walk,idle}[-axe].png       64x64 character sheets composed from layers, clothes recoloured,
                                   with and without the axe in hand
  hero-{chop,hammer}.png           128x128 work animations: body slash frames between the tool's
                                   back and front layers (same layout as the LPC generator)
  forest.png + forest.json         Phaser JSON-hash atlas: trees (pivot = trunk base), decor, stump,
                                   axe pickup and the house (pivot = bottom centre)
  ground.png                       grass tile(s) for the tilemap (32x32 each, in a row)

Requires Pillow. Licences and authors: see CREDITS.md next to the outputs.
"""

from pathlib import Path
import json
import shutil

from PIL import Image

ROOT = Path(__file__).parent
SOURCES = ROOT / "sources"
OUT = ROOT.parent.parent / "lib" / "core" / "assets" / "images" / "lpc"
LEGACY_OUT = ROOT.parent.parent / "shared" / "assets" / "lpc"

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


FRAME = 64
WORK_FRAME = 128
DIRECTIONS = 4


def body_sheet(animation: str) -> Image.Image:
    sheet = None
    for layer in CHARACTER_LAYERS:
        image = Image.open(SOURCES / "character" / f"{layer}__{animation}.png").convert("RGBA")
        if layer in RECOLOURS:
            image = recolour(image, *RECOLOURS[layer])
        sheet = image if sheet is None else Image.alpha_composite(sheet, image)
    return sheet


def tool(name: str) -> Image.Image:
    return Image.open(SOURCES / "tools" / f"{name}.png").convert("RGBA")


def with_idle_axe(idle: Image.Image) -> Image.Image:
    """The axe only ships a walk sheet; its standing pose (column 0) is reused for every idle frame."""
    axe = tool("axe_walk")
    sheet = idle.copy()
    for row in range(DIRECTIONS):
        pose = axe.crop((0, row * FRAME, FRAME, (row + 1) * FRAME))
        for column in range(idle.width // FRAME):
            sheet.alpha_composite(pose, (column * FRAME, row * FRAME))
    return sheet


def work_sheet(slash: Image.Image, tool_name: str) -> Image.Image:
    """Tool back layer, then the 64px body slash frames centred in 128px cells, then the tool front."""
    back, front = tool(f"{tool_name}_bg"), tool(f"{tool_name}_fg")
    sheet = Image.new("RGBA", back.size)
    sheet.alpha_composite(back)
    offset = (WORK_FRAME - FRAME) // 2
    for row in range(DIRECTIONS):
        for column in range(slash.width // FRAME):
            frame = slash.crop((column * FRAME, row * FRAME, (column + 1) * FRAME, (row + 1) * FRAME))
            sheet.alpha_composite(frame, (column * WORK_FRAME + offset, row * WORK_FRAME + offset))
    sheet.alpha_composite(front)
    return sheet


def build_character() -> None:
    walk, idle, slash = body_sheet("walk"), body_sheet("idle"), body_sheet("slash")
    walk.save(OUT / "hero-walk.png")
    idle.save(OUT / "hero-idle.png")
    Image.alpha_composite(walk, tool("axe_walk")).save(OUT / "hero-walk-axe.png")
    with_idle_axe(idle).save(OUT / "hero-idle-axe.png")
    work_sheet(slash, "axe").save(OUT / "hero-chop.png")
    work_sheet(slash, "hammer").save(OUT / "hero-hammer.png")


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
# Pixel boxes (x0, y0, x1, y1) of single sprites.
STUMP_BOX = (391, 395, 441, 436)  # terrain_atlas.png
AXE_PICKUP = (1, 5)  # (row, column) of a 128px axe frame (back + front layers) showing the whole axe

# House assembled from LPC cottage pieces: a 3x3 timber-frame wall, a thatched hip roof on top
# (overlapping the wall's top edge) and a door centred at the bottom.
HOUSE_WALL_BOX = (0, 128, 96, 224)  # cottage.png
HOUSE_ROOF_BOX = (80, 0, 215, 128)  # thatched-roof.png
HOUSE_DOOR_BOX = (16, 0, 48, 48)  # doors_0.png
HOUSE_ROOF_OVERLAP = 28


def trim(image: Image.Image, name: str) -> Image.Image:
    """Crops to the visible pixels; fails loudly instead of shipping an empty sprite."""
    box = image.getbbox()
    if box is None:
        raise ValueError(f"{name}: the source region is fully transparent")
    return image.crop(box)


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


def build_house() -> Image.Image:
    buildings = SOURCES / "buildings"
    wall = Image.open(buildings / "cottage.png").convert("RGBA").crop(HOUSE_WALL_BOX)
    roof = Image.open(buildings / "thatched-roof.png").convert("RGBA").crop(HOUSE_ROOF_BOX)
    roof = roof.crop(roof.getbbox())
    door = Image.open(buildings / "doors_0.png").convert("RGBA").crop(HOUSE_DOOR_BOX)
    door = door.crop(door.getbbox())

    width = max(roof.width, wall.width)
    house = Image.new("RGBA", (width, roof.height + wall.height - HOUSE_ROOF_OVERLAP))
    wall_x, wall_y = (width - wall.width) // 2, roof.height - HOUSE_ROOF_OVERLAP
    house.alpha_composite(wall, (wall_x, wall_y))
    house.alpha_composite(door, (wall_x + (wall.width - door.width) // 2, wall_y + wall.height - door.height))
    house.alpha_composite(roof, ((width - roof.width) // 2, 0))
    return house


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
        frames[name] = trim(image, name)
        pivots[name] = {"x": 0.5, "y": 1}

    frames["stump"] = terrain.crop(STUMP_BOX)
    pivots["stump"] = {"x": 0.5, "y": 0.85}
    row, column = AXE_PICKUP
    cell = (column * WORK_FRAME, row * WORK_FRAME, (column + 1) * WORK_FRAME, (row + 1) * WORK_FRAME)
    axe = Image.alpha_composite(tool("axe_bg"), tool("axe_fg")).crop(cell)
    frames["axe-pickup"] = trim(axe, "axe-pickup")
    pivots["axe-pickup"] = {"x": 0.5, "y": 0.5}
    frames["house"] = build_house()
    pivots["house"] = {"x": 0.5, "y": 1}

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
    if LEGACY_OUT.parent.exists():
        shutil.copytree(OUT, LEGACY_OUT, dirs_exist_ok=True)
        print(f"Assets mirrored to {LEGACY_OUT}")
