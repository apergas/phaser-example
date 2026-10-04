import type * as Phaser from 'phaser';
import type { Point } from '../../../../domain/usecases/models/Point';
import { ForestAtlas } from '../../../common/assets';
import { Depth } from '../../../common/depth';

const FLOAT_HEIGHT = 8;

/** A tool lying on the ground, gently bobbing so it catches the eye. */
export class ItemView {
  private readonly scene: Phaser.Scene;
  private readonly shadow: Phaser.GameObjects.Ellipse;
  private readonly image: Phaser.GameObjects.Image;

  constructor(scene: Phaser.Scene, position: Point) {
    this.scene = scene;
    this.shadow = scene.add.ellipse(position.x, position.y, 16, 5, 0x000000, 0.3).setDepth(Depth.SHADOW);
    this.image = scene.add
      .image(position.x, position.y - FLOAT_HEIGHT, ForestAtlas.key, ForestAtlas.AXE_PICKUP)
      .setDepth(Depth.bySortY(position.y));

    scene.tweens.add({
      targets: this.image,
      y: position.y - FLOAT_HEIGHT - 3,
      duration: 700,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    });
  }

  get bounds(): Phaser.Geom.Rectangle {
    return this.image.getBounds();
  }

  /** Pops up and vanishes. */
  pickUp(): void {
    this.shadow.destroy();
    this.scene.tweens.killTweensOf(this.image);
    this.scene.tweens.add({
      targets: this.image,
      y: this.image.y - 16,
      alpha: 0,
      duration: 300,
      onComplete: () => this.image.destroy(),
    });
  }
}
