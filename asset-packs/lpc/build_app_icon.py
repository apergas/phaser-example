"""Draws the app icon from the oak of the forest atlas and writes it for Android, iOS and the web.

  python3 build_app_icon.py      (run build_assets.py first: it reads lib/core/assets/images/lpc/forest.*)

The oak (`tree-oak`) is scaled with nearest neighbour to a 1024 px master on the launch colour #0E150E,
then every platform size is resized from that master. The Android adaptive icon foreground is the same oak on a
transparent master (inside the 66 dp safe zone of the 108 dp layer), over the launch colour set in
android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml.
"""

import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).parent
REPO = ROOT.parent.parent
ART = REPO / "lib" / "core" / "assets" / "images" / "lpc"
MASTER_SIZE = 1024
BACKGROUND = (0x0E, 0x15, 0x0E)
FRAME = "tree-oak"
COVERAGE = 0.8
MASKABLE_COVERAGE = 0.6
FOREGROUND_COVERAGE = 0.5
ANDROID_SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
ANDROID_FOREGROUND_SIZES = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
ANDROID_RES = REPO / "android" / "app" / "src" / "main" / "res"
IOS_ICONSET = REPO / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
WEB = REPO / "web"


def oak_icon(coverage, background=BACKGROUND):
    frames = json.loads((ART / "forest.json").read_text())["frames"]
    rect = frames[FRAME]["frame"]
    sheet = Image.open(ART / "forest.png").convert("RGBA")
    sprite = sheet.crop((rect["x"], rect["y"], rect["x"] + rect["w"], rect["y"] + rect["h"]))
    scale = int(MASTER_SIZE * coverage) // max(rect["w"], rect["h"])
    sprite = sprite.resize((rect["w"] * scale, rect["h"] * scale), Image.NEAREST)
    icon = Image.new("RGBA", (MASTER_SIZE, MASTER_SIZE), background + (255,) if background else (0, 0, 0, 0))
    icon.paste(sprite, ((MASTER_SIZE - sprite.width) // 2, (MASTER_SIZE - sprite.height) // 2), sprite)
    return icon.convert("RGB") if background else icon


def save(icon, size, path):
    icon.resize((size, size), Image.LANCZOS).save(path)


def main():
    icon = oak_icon(COVERAGE)
    maskable = oak_icon(MASKABLE_COVERAGE)
    foreground = oak_icon(FOREGROUND_COVERAGE, None)
    for density, size in ANDROID_SIZES.items():
        save(icon, size, ANDROID_RES / f"mipmap-{density}" / "ic_launcher.png")
    for density, size in ANDROID_FOREGROUND_SIZES.items():
        save(foreground, size, ANDROID_RES / f"mipmap-{density}" / "ic_launcher_foreground.png")
    for image in json.loads((IOS_ICONSET / "Contents.json").read_text())["images"]:
        points = float(image["size"].split("x")[0])
        save(icon, round(points * int(image["scale"][0])), IOS_ICONSET / image["filename"])
    for size in (192, 512):
        save(icon, size, WEB / "icons" / f"Icon-{size}.png")
        save(maskable, size, WEB / "icons" / f"Icon-maskable-{size}.png")
    save(icon, 32, WEB / "favicon.png")
    print(f"{FRAME} -> {MASTER_SIZE} px master, Android, iOS and web icons written")


if __name__ == "__main__":
    main()
