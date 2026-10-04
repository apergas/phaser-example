import type * as Phaser from 'phaser';
import type { WebPlayer, WebPoint } from 'rpg-shared';
import { CHARACTER_ORIGIN_Y, FACING_DIRECTIONS, type FacingDirection, WorkSheet, WorkSheets } from '../../../common/assets';
import { Depth } from '../../../common/depth';

export function heroAnimationKey(state: 'walk' | 'idle', direction: FacingDirection, withAxe: boolean): string {
  return `hero-${state}-${direction}${withAxe ? '-axe' : ''}`;
}

/** Draws the player from the shared view model's state; only maps it to LPC sheets. */
export class PlayerView {
  private readonly shadow: Phaser.GameObjects.Ellipse;
  private readonly sprite: Phaser.GameObjects.Sprite;

  constructor(scene: Phaser.Scene, initial: WebPoint) {
    this.shadow = scene.add.ellipse(0, 0, 22, 7, 0x000000, 0.3).setDepth(Depth.SHADOW);
    this.sprite = scene.add.sprite(initial.x, initial.y, WorkSheets.CHOP.key);
  }

  get followTarget(): Phaser.GameObjects.Sprite {
    return this.sprite;
  }

  render(player: WebPlayer): void {
    const facing = player.facing as FacingDirection;
    if (player.pose === 'work') {
      const [sheet, sequence] =
        player.tool === 'axe' ? [WorkSheets.CHOP, WorkSheet.CHOP_SEQUENCE] : [WorkSheets.HAMMER, WorkSheet.HAMMER_SEQUENCE];
      const step = Math.min(sequence.length - 1, Math.floor(player.swingProgress * sequence.length));
      this.sprite.anims.stop();
      this.sprite.setTexture(sheet.key, FACING_DIRECTIONS.indexOf(facing) * WorkSheet.COLUMNS + sequence[step]);
      this.sprite.setOrigin(0.5, WorkSheet.ORIGIN_Y);
    } else {
      this.sprite.setOrigin(0.5, CHARACTER_ORIGIN_Y);
      this.sprite.anims.play(heroAnimationKey(player.pose === 'walk' ? 'walk' : 'idle', facing, player.withAxe), true);
    }

    const { x, y } = player.position;
    this.shadow.setPosition(x, y - 1);
    this.sprite.setPosition(x, y).setDepth(Depth.bySortY(y));
  }
}
