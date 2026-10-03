import type * as Phaser from 'phaser';
import type { Position } from '../../../domain/value-objects/Position';
import { ForestAtlas } from '../assets';
import { Depth } from './depth';

/**
 * Static tree sprite. The atlas frame's pivot is the base of the trunk, so the sprite is anchored
 * at the obstacle position and y-sorting works. The shadow is painted into the art itself.
 */
export class TreeView {
  private readonly image: Phaser.GameObjects.Image;

  /** @param frame one of ForestAtlas.TREES */
  constructor(scene: Phaser.Scene, base: Position, frame: string) {
    this.image = scene.add.image(base.x, base.y, ForestAtlas.key, frame).setDepth(Depth.bySortY(base.y));
  }

  /** Area covered on screen, so other elements can avoid overlapping it. */
  get bounds(): Phaser.Geom.Rectangle {
    return this.image.getBounds();
  }
}
