import type * as Phaser from 'phaser';
import type { Point } from '../../../../domain/usecases/models/Point';
import { ForestAtlas, GeneratedTextures, HOUSE_FRONT_OFFSET } from '../../../common/assets';
import { Depth } from '../../../common/depth';

const SITE_ALPHA = 0.35;
const BAR_WIDTH = 60;
const BAR_HEIGHT = 5;
/** Gap between the top of the house and its progress bar. */
const BAR_MARGIN = 6;

/** Draws a house where `position` is the centre of its ground footprint. */
export function addHouseImage(scene: Phaser.Scene, position: Point): Phaser.GameObjects.Image {
  return placeHouseImage(scene.add.image(0, 0, ForestAtlas.key, ForestAtlas.HOUSE), position);
}

/** Anchors a house image to a footprint centre: the front wall sits below it, y-sorted by that wall. */
export function placeHouseImage(image: Phaser.GameObjects.Image, position: Point): Phaser.GameObjects.Image {
  const frontY = position.y + HOUSE_FRONT_OFFSET;
  return image.setPosition(position.x, frontY).setDepth(Depth.bySortY(frontY));
}

/**
 * A building in the world. While under construction it is translucent, becomes more solid with each
 * hammer hit and shows a progress bar; once complete it settles with a small bounce.
 */
export class BuildingView {
  private readonly scene: Phaser.Scene;
  private readonly image: Phaser.GameObjects.Image;
  private readonly bar: Phaser.GameObjects.Graphics;

  constructor(scene: Phaser.Scene, position: Point, progress: number) {
    this.scene = scene;
    this.image = addHouseImage(scene, position);
    this.bar = scene.add.graphics().setDepth(Depth.bySortY(this.image.y) + 1);
    this.setProgress(progress);
  }

  get bounds(): Phaser.Geom.Rectangle {
    return this.image.getBounds();
  }

  setProgress(progress: number): void {
    this.image.setAlpha(SITE_ALPHA + (1 - SITE_ALPHA) * progress);

    const bounds = this.image.getBounds();
    const x = bounds.centerX - BAR_WIDTH / 2;
    const y = bounds.top - BAR_MARGIN - BAR_HEIGHT;
    this.bar.clear();
    this.bar.fillStyle(0x000000, 0.6).fillRect(x - 1, y - 1, BAR_WIDTH + 2, BAR_HEIGHT + 2);
    this.bar.fillStyle(0xe8c05a, 1).fillRect(x, y, BAR_WIDTH * progress, BAR_HEIGHT);
  }

  /** Hammer impact: a puff of dust at the front wall. */
  hammered(progress: number): void {
    this.setProgress(progress);
    const dust = this.scene.add.particles(this.image.x, this.image.y - 4, GeneratedTextures.DUST, {
      speed: { min: 10, max: 35 },
      angle: { min: 180, max: 360 },
      lifespan: 450,
      scale: { start: 0.8, end: 0.2 },
      alpha: { start: 0.7, end: 0 },
      emitting: false,
    });
    dust.setDepth(this.image.depth + 1);
    dust.explode(6);
    this.scene.time.delayedCall(500, () => dust.destroy());
  }

  complete(): void {
    this.setProgress(1);
    this.bar.destroy();
    this.scene.tweens.add({ targets: this.image, scaleY: { from: 0.92, to: 1 }, duration: 350, ease: 'Back.easeOut' });
  }
}
