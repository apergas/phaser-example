import * as Phaser from 'phaser';
import { seededRandom } from '../../../../shared/seededRandom';
import { ForestAtlas, GroundFrames, Sheets, TILE_SIZE } from '../../../common/assets';
import { Depth } from '../../../common/depth';

const SEED = 1337;
const DECOR_PER_PIXEL = 1 / 18000;
const MAX_PLACEMENT_ATTEMPTS = 20;

/**
 * Grass tilemap covering the world plus scattered non-solid decor (tall grass, bushes, rocks...).
 * Decor placement is seeded, so it looks the same every run.
 */
export class GroundView {
  /** Non-solid decor sprites, so buildings can clear what ends up underneath them. */
  readonly decor: Phaser.GameObjects.Image[] = [];

  /** @param occupied areas already taken (e.g. trees) where decor must not be placed */
  constructor(scene: Phaser.Scene, width: number, height: number, occupied: readonly Phaser.Geom.Rectangle[]) {
    const random = seededRandom(SEED);
    const columns = Math.ceil(width / TILE_SIZE);
    const rows = Math.ceil(height / TILE_SIZE);

    const map = scene.make.tilemap({ tileWidth: TILE_SIZE, tileHeight: TILE_SIZE, width: columns, height: rows });
    const tileset = map.addTilesetImage(Sheets.GROUND.key, Sheets.GROUND.key, TILE_SIZE, TILE_SIZE, 0, 0);
    const layer = tileset && map.createBlankLayer('ground', tileset);
    if (!layer) throw new Error('Could not create ground layer');

    layer.setDepth(Depth.GROUND);
    for (let row = 0; row < rows; row++) {
      for (let column = 0; column < columns; column++) {
        layer.putTileAt(GroundFrames.GRASS, column, row);
      }
    }

    const taken = [...occupied];
    const decorCount = Math.round(width * height * DECOR_PER_PIXEL);
    for (let i = 0; i < decorCount; i++) {
      const frame = ForestAtlas.DECOR[Math.floor(random() * ForestAtlas.DECOR.length)];
      const decor = scene.add.image(0, 0, ForestAtlas.key, frame);

      if (!placeInFreeSpot(decor, random, width, height, taken)) {
        decor.destroy();
        continue;
      }
      decor.setDepth(Depth.bySortY(decor.y));
      taken.push(decor.getBounds());
      this.decor.push(decor);
    }
  }
}

function placeInFreeSpot(
  decor: Phaser.GameObjects.Image,
  random: () => number,
  width: number,
  height: number,
  taken: readonly Phaser.Geom.Rectangle[],
): boolean {
  for (let attempt = 0; attempt < MAX_PLACEMENT_ATTEMPTS; attempt++) {
    decor.setPosition(random() * width, random() * height);
    const bounds = decor.getBounds();
    if (!taken.some((area) => Phaser.Geom.Intersects.RectangleToRectangle(area, bounds))) return true;
  }
  return false;
}
