import * as Phaser from 'phaser';
import type { WebDecoration } from 'rpg-shared';
import { ForestAtlas, GroundFrames, Sheets, TILE_SIZE } from '../../../common/assets';
import { Depth } from '../../../common/depth';

/** Grass tilemap covering the world, plus the level's decoration (non-solid) where the level puts it. */
export class GroundView {
  /** Decoration sprites, so buildings can clear what ends up underneath them. */
  readonly decor: Phaser.GameObjects.Image[] = [];

  constructor(scene: Phaser.Scene, width: number, height: number, decorations: readonly WebDecoration[]) {
    const columns = Math.ceil(width / TILE_SIZE);
    const rows = Math.ceil(height / TILE_SIZE);
    const map = scene.make.tilemap({ tileWidth: TILE_SIZE, tileHeight: TILE_SIZE, width: columns, height: rows });
    const tileset = map.addTilesetImage(Sheets.GROUND.key, Sheets.GROUND.key, TILE_SIZE, TILE_SIZE, 0, 0);
    const layer = tileset && map.createBlankLayer('ground', tileset);
    if (!layer) throw new Error('Could not create ground layer');

    layer.setDepth(Depth.GROUND);
    for (let row = 0; row < rows; row++) {
      for (let column = 0; column < columns; column++) layer.putTileAt(GroundFrames.GRASS, column, row);
    }

    for (const decoration of decorations) {
      const { x, y } = decoration.position;
      this.decor.push(scene.add.image(x, y, ForestAtlas.key, decoration.frame).setDepth(Depth.bySortY(y)));
    }
  }
}
