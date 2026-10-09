"""
Builds the game's LPC textures from the raw sources in ./sources.

  python3 build_assets.py

Outputs (into lib/core/assets/images/lpc/, the one copy the Flutter app reads on every platform):
  hero-{walk,idle}[-axe].png       64x64 character sheets composed from layers, clothes recoloured,
                                   with and without the axe in hand
  hero-{chop,hammer}.png           128x128 work animations: body slash frames between the tool's
                                   back and front layers (same layout as the LPC generator)
  forest.png + forest.json         JSON-hash atlas (TexturePacker format): trees (pivot = trunk base), decor, stump,
                                   axe pickup, the house, the forge, the armory and the mage tower
                                   (pivot = bottom centre)
  ground.png                       grass tile(s) for the tilemap (32x32 each, in a row)
  arena.png + arena.json           JSON-hash atlas for the arena: hero, bandit and barbarian idle (64px, axe in
                                   hand) and slash (128px) frames in their one facing (pivot = feet), the wolf
                                   and bear idle, attack and down frames facing left, the grass cell and a fence
                                   segment

Requires Pillow. Licences and authors: see CREDITS.md next to the outputs.
"""

from pathlib import Path
import json

from PIL import Image

ROOT = Path(__file__).parent
SOURCES = ROOT / "sources"
OUT = ROOT.parent.parent / "lib" / "core" / "assets" / "images" / "lpc"

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


def body_sheet(animation: str, recolours: dict = RECOLOURS) -> Image.Image:
    sheet = None
    for layer in CHARACTER_LAYERS:
        image = Image.open(SOURCES / "character" / f"{layer}__{animation}.png").convert("RGBA")
        if layer in recolours:
            image = recolour(image, *recolours[layer])
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

# Forge and armory reuse the house layout. The thatch ships in exactly these nine colours (dark -> light),
# so recolour() swaps the whole roof; the wall and door keep their own colours.
ROOF_RAMP = [(43, 28, 29), (48, 33, 36), (98, 53, 28), (112, 86, 55), (137, 103, 56), (154, 114, 57), (183, 149, 67), (227, 198, 84), (237, 226, 108)]
FORGE_ROOF = [(20, 20, 24), (26, 26, 30), (40, 40, 46), (54, 54, 60), (66, 66, 74), (76, 76, 84), (94, 94, 102), (118, 118, 126), (136, 136, 144)]
ARMORY_ROOF = [(40, 14, 16), (46, 18, 20), (90, 24, 22), (110, 32, 28), (132, 40, 34), (148, 46, 38), (176, 60, 46), (212, 90, 68), (228, 118, 90)]
FORGE_WALL_BOX = (0, 256, 96, 352)  # cottage.png, stone wall with timber frame
CHIMNEY_BOX = (448, 480, 480, 512)  # terrain_atlas.png, cracked stone block
CHIMNEY_RISE = 18  # pixels the chimney sticks out above the roof
CHIMNEY_INSET = 20  # distance from the chimney's right edge to the roof's right edge
MAGE_TOWER_ROOF = [(30, 16, 40), (38, 20, 52), (62, 30, 92), (78, 40, 112), (96, 52, 136), (110, 62, 152), (134, 84, 178), (168, 120, 210), (190, 150, 226)]
MAGE_TOWER_WALL_BOX = (96, 256, 192, 352)  # cottage.png, stone wall with long diagonal braces
MAGE_TOWER_ROOF_STRETCH = 1.4  # the violet roof is drawn 40 % taller, like a spire


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


def build_cottage(
    wall_box: tuple, roof_colours: list = None, chimney: Image.Image = None, roof_stretch: float = 1
) -> Image.Image:
    """Wall, door and thatched roof; optionally a recoloured, taller roof and a chimney sticking out of it."""
    buildings = SOURCES / "buildings"
    wall = Image.open(buildings / "cottage.png").convert("RGBA").crop(wall_box)
    roof = Image.open(buildings / "thatched-roof.png").convert("RGBA").crop(HOUSE_ROOF_BOX)
    roof = roof.crop(roof.getbbox())
    if roof_colours is not None:
        roof = recolour(roof, ROOF_RAMP, roof_colours)
    if roof_stretch != 1:
        roof = roof.resize((roof.width, round(roof.height * roof_stretch)), Image.NEAREST)
    door = Image.open(buildings / "doors_0.png").convert("RGBA").crop(HOUSE_DOOR_BOX)
    door = door.crop(door.getbbox())

    top = CHIMNEY_RISE if chimney is not None else 0
    width = max(roof.width, wall.width)
    image = Image.new("RGBA", (width, top + roof.height + wall.height - HOUSE_ROOF_OVERLAP))
    wall_x, wall_y = (width - wall.width) // 2, top + roof.height - HOUSE_ROOF_OVERLAP
    image.alpha_composite(wall, (wall_x, wall_y))
    image.alpha_composite(door, (wall_x + (wall.width - door.width) // 2, wall_y + wall.height - door.height))
    image.alpha_composite(roof, ((width - roof.width) // 2, top))
    if chimney is not None:
        image.alpha_composite(chimney, (width - chimney.width - CHIMNEY_INSET, 0))
    return image


def build_house() -> Image.Image:
    return build_cottage(HOUSE_WALL_BOX)


def build_forge(terrain: Image.Image) -> Image.Image:
    return build_cottage(FORGE_WALL_BOX, FORGE_ROOF, trim(terrain.crop(CHIMNEY_BOX), "chimney"))


def build_armory() -> Image.Image:
    return build_cottage(HOUSE_WALL_BOX, ARMORY_ROOF)


def build_mage_tower() -> Image.Image:
    return build_cottage(MAGE_TOWER_WALL_BOX, MAGE_TOWER_ROOF, roof_stretch=MAGE_TOWER_ROOF_STRETCH)


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
    frames["forge"] = build_forge(terrain)
    pivots["forge"] = {"x": 0.5, "y": 1}
    frames["armory"] = build_armory()
    pivots["armory"] = {"x": 0.5, "y": 1}
    frames["mage-tower"] = build_mage_tower()
    pivots["mage-tower"] = {"x": 0.5, "y": 1}

    write_atlas("forest", frames, pivots)

    ground = Image.new("RGBA", (CELL * len(GROUND_TILES), CELL))
    for index, (column, row) in enumerate(GROUND_TILES):
        ground.alpha_composite(terrain.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL)), (index * CELL, 0))
    ground.save(OUT / "ground.png")


def write_atlas(atlas_name: str, frames: dict, pivots: dict) -> None:
    atlas, positions = pack(frames)
    atlas.save(OUT / f"{atlas_name}.png")
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
        "meta": {"image": f"{atlas_name}.png", "size": {"w": atlas.width, "h": atlas.height}, "scale": "1"},
    }
    (OUT / f"{atlas_name}.json").write_text(json.dumps(data, indent=1))


# --- Arena atlas -----------------------------------------------------------------------------

# Skin ships in the human ramp, dark -> light; body and head share it.
SKIN_RAMP = [(153, 66, 60), (204, 134, 101), (228, 164, 124), (249, 213, 186), (250, 236, 231)]
BANDIT_RECOLOURS = {
    **RECOLOURS,
    "torso_clothes_longsleeve_longsleeve_male": (CLOTH_RAMP, [(48, 14, 16), (82, 22, 24), (112, 32, 30), (140, 46, 40), (168, 64, 54)]),
    "legs_pants_male": (CLOTH_RAMP, [(28, 22, 24), (44, 34, 36), (62, 48, 48), (82, 64, 62), (104, 82, 78)]),
    "hair_plain_adult": (HAIR_RAMP, [(20, 16, 16), (32, 26, 24), (46, 38, 34), (60, 50, 44), (76, 64, 56)]),
}
BARBARIAN_SKIN = [(78, 38, 30), (120, 72, 50), (146, 96, 66), (172, 122, 88), (196, 156, 126)]
BARBARIAN_RECOLOURS = {
    **RECOLOURS,
    "body_bodies_male": (SKIN_RAMP, BARBARIAN_SKIN),
    "head_heads_human_male": (SKIN_RAMP, BARBARIAN_SKIN),
    "torso_clothes_longsleeve_longsleeve_male": (CLOTH_RAMP, [(44, 28, 16), (74, 48, 26), (102, 68, 38), (130, 90, 52), (158, 114, 70)]),
    "legs_pants_male": (CLOTH_RAMP, [(36, 26, 18), (58, 42, 28), (80, 58, 38), (104, 76, 50), (128, 96, 64)]),
    "hair_plain_adult": (HAIR_RAMP, [(60, 20, 8), (92, 34, 12), (120, 50, 18), (148, 68, 26), (176, 90, 38)]),
}
# Fighter -> (recolours, LPC row): the hero faces right (row 3), the enemies face left (row 1).
ARENA_FIGHTERS = {
    "hero": (RECOLOURS, 3),
    "bandit": (BANDIT_RECOLOURS, 1),
    "barbarian": (BARBARIAN_RECOLOURS, 1),
}
ARENA_GRASS = (1, 23)  # (column, row) of terrain_atlas.png, the same grass as the forest ground
ARENA_FENCE_BOX = (480, 608, 544, 640)  # terrain_atlas.png: a post and a rail, 64x32, tiles horizontally
IDLE_PIVOT = {"x": 0.5, "y": round(62 / FRAME, 4)}
SLASH_PIVOT = {"x": 0.5, "y": round((32 + 62) / WORK_FRAME, 4)}
# Beast -> (sheet in sources/creatures, origin of the side views, cell size, animations). The rows used already face
# left. Each animation is (row, columns, ground): one frame per column, and ground = the pixel row the paws stand on
# in that row (the pivot, like the feet of the people). A single column is named without an index ("wolf-down").
ARENA_BEASTS = {
    "wolf": (
        "wolfsheet1.png",
        (320, 0),
        (64, 32),
        {"idle": (9, [0, 1], 32), "attack": (11, [0, 1, 2, 3, 4], 32), "down": (6, [3], 32)},
    ),
    "bear": (
        "bear-grizzly.png",
        (0, 0),
        (64, 64),
        {"idle": (2, [0, 1], 62), "attack": (6, [0, 1, 2], 58), "down": (10, [3], 57)},
    ),
}


def cells(sheet: Image.Image, row: int, size: int) -> list:
    return [sheet.crop((column * size, row * size, (column + 1) * size, (row + 1) * size)) for column in range(sheet.width // size)]


def add_beasts(frames: dict, pivots: dict) -> None:
    for beast, (file_name, (origin_x, origin_y), (width, height), animations) in ARENA_BEASTS.items():
        sheet = Image.open(SOURCES / "creatures" / file_name).convert("RGBA")
        for animation, (row, columns, ground) in animations.items():
            for index, column in enumerate(columns):
                x, y = origin_x + column * width, origin_y + row * height
                name = f"{beast}-{animation}" if len(columns) == 1 else f"{beast}-{animation}-{index}"
                cell = sheet.crop((x, y, x + width, y + height))
                trim(cell, name)
                frames[name], pivots[name] = cell, {"x": 0.5, "y": round(ground / height, 4)}


def build_arena() -> None:
    terrain = Image.open(SOURCES / "terrain" / "terrain_atlas.png").convert("RGBA")
    frames, pivots = {}, {}
    for fighter, (recolours, row) in ARENA_FIGHTERS.items():
        idle = with_idle_axe(body_sheet("idle", recolours))
        slash = work_sheet(body_sheet("slash", recolours), "axe")
        for column, image in enumerate(cells(idle, row, FRAME)):
            frames[f"{fighter}-idle-{column}"], pivots[f"{fighter}-idle-{column}"] = image, IDLE_PIVOT
        for column, image in enumerate(cells(slash, row, WORK_FRAME)):
            frames[f"{fighter}-slash-{column}"], pivots[f"{fighter}-slash-{column}"] = image, SLASH_PIVOT
    add_beasts(frames, pivots)
    column, row = ARENA_GRASS
    frames["arena-grass"] = terrain.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))
    pivots["arena-grass"] = {"x": 0, "y": 0}
    frames["arena-fence"] = trim(terrain.crop(ARENA_FENCE_BOX), "arena-fence")
    pivots["arena-fence"] = {"x": 0, "y": 1}
    write_atlas("arena", frames, pivots)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    build_character()
    build_forest()
    build_arena()
    print(f"Assets written to {OUT}")
