import * as Phaser from 'phaser';
import type { Point } from '../../../../domain/usecases/models/Point';
import { ForestAtlas, GeneratedTextures } from '../../../common/assets';
import { Depth } from '../../../common/depth';

const SHAKE_ANGLE = 3;
const SHAKE_MS = 70;
const CHIPS_PER_HIT = 8;
const FALL_MS = 700;
/** Height above the trunk base where the axe hits, for the wood chips. */
const IMPACT_HEIGHT = 10;
/** Pixels at least this opaque count as the tree when clicked; the painted shadow is fainter. */
const SOLID_ALPHA = 200;

/**
 * Tree sprite. The atlas frame's pivot is the base of the trunk, so the sprite is anchored at the
 * tree position, y-sorting works, and rotating it (shake, fall) pivots around the trunk base.
 */
export class TreeView {
  private readonly scene: Phaser.Scene;
  private readonly base: Point;
  private readonly image: Phaser.GameObjects.Image;

  /** @param frame one of ForestAtlas.TREES */
  constructor(scene: Phaser.Scene, base: Point, frame: string) {
    this.scene = scene;
    this.base = base;
    this.image = scene.add.image(base.x, base.y, ForestAtlas.key, frame).setDepth(Depth.bySortY(base.y));
  }

  /** Area covered on screen, so other elements can avoid overlapping it. */
  get bounds(): Phaser.Geom.Rectangle {
    return this.image.getBounds();
  }

  get depth(): number {
    return this.image.depth;
  }

  /** Pixel-accurate hit test: transparent gaps and the translucent shadow do not count. */
  containsPoint(x: number, y: number): boolean {
    if (!this.bounds.contains(x, y)) return false;

    const local = this.image.getLocalPoint(x, y);
    const alpha = this.scene.textures.getPixelAlpha(
      Math.floor(local.x),
      Math.floor(local.y),
      ForestAtlas.key,
      this.image.frame.name,
    );
    return (alpha ?? 0) >= SOLID_ALPHA;
  }

  /** Axe impact: a quick shake and a burst of wood chips. */
  hit(fromX: number): void {
    const direction = fromX < this.base.x ? 1 : -1;
    this.scene.tweens.add({
      targets: this.image,
      angle: { from: 0, to: SHAKE_ANGLE * direction },
      duration: SHAKE_MS,
      yoyo: true,
      ease: 'Sine.easeOut',
    });

    const chips = this.scene.add.particles(this.base.x, this.base.y - IMPACT_HEIGHT, GeneratedTextures.WOOD_CHIP, {
      speed: { min: 30, max: 80 },
      angle: direction > 0 ? { min: 200, max: 290 } : { min: 250, max: 340 },
      gravityY: 220,
      lifespan: 500,
      rotate: { min: 0, max: 360 },
      alpha: { start: 1, end: 0 },
      emitting: false,
    });
    chips.setDepth(Depth.bySortY(this.base.y) + 1);
    chips.explode(CHIPS_PER_HIT);
    this.scene.time.delayedCall(600, () => chips.destroy());
  }

  /** Falls away from the player, fades out and leaves a stump behind, which it returns. */
  fell(fromX: number): Phaser.GameObjects.Image {
    const direction = fromX < this.base.x ? 1 : -1;
    const stump = this.scene.add
      .image(this.base.x, this.base.y, ForestAtlas.key, ForestAtlas.STUMP)
      .setDepth(Depth.bySortY(this.base.y) - 1);

    this.scene.tweens.add({
      targets: this.image,
      angle: 85 * direction,
      alpha: 0,
      duration: FALL_MS,
      ease: 'Quad.easeIn',
      onComplete: () => this.image.destroy(),
    });
    return stump;
  }
}
