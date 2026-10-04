import type * as Phaser from 'phaser';
import type { PointDto } from '../../../application/dto';
import type { Facing, PlayerRenderState } from '../../viewmodels/PlayerViewModel';
import { CHARACTER_ORIGIN_Y, FACING_DIRECTIONS, WorkSheet, WorkSheets } from '../assets';
import { Depth } from './depth';

export function heroAnimationKey(state: 'walk' | 'idle', direction: Facing, withAxe: boolean): string {
  return `hero-${state}-${direction}${withAxe ? '-axe' : ''}`;
}

/**
 * Draws the player from `PlayerRenderState`. Decides nothing about facing or pose; it only maps
 * them to LPC sheets. Work swings are drawn frame by frame from the swing progress, so the impact
 * frame lines up with the actual hit.
 */
export class PlayerView {
  private readonly shadow: Phaser.GameObjects.Ellipse;
  private readonly sprite: Phaser.GameObjects.Sprite;

  constructor(scene: Phaser.Scene, initial: PointDto) {
    this.shadow = scene.add.ellipse(0, 0, 22, 7, 0x000000, 0.3).setDepth(Depth.SHADOW);
    this.sprite = scene.add.sprite(initial.x, initial.y, WorkSheets.CHOP.key);
  }

  /** Game object the camera should follow. */
  get followTarget(): Phaser.GameObjects.Sprite {
    return this.sprite;
  }

  render(state: PlayerRenderState): void {
    const { position, facing, pose } = state;

    if (pose.kind === 'work') {
      const [sheet, sequence] =
        pose.tool === 'axe' ? [WorkSheets.CHOP, WorkSheet.CHOP_SEQUENCE] : [WorkSheets.HAMMER, WorkSheet.HAMMER_SEQUENCE];
      const step = Math.min(sequence.length - 1, Math.floor(pose.swingProgress * sequence.length));
      this.sprite.anims.stop();
      this.sprite.setTexture(sheet.key, FACING_DIRECTIONS.indexOf(facing) * WorkSheet.COLUMNS + sequence[step]);
      this.sprite.setOrigin(0.5, WorkSheet.ORIGIN_Y);
    } else {
      this.sprite.setOrigin(0.5, CHARACTER_ORIGIN_Y);
      this.sprite.anims.play(heroAnimationKey(pose.kind, facing, pose.withAxe), true);
    }

    this.shadow.setPosition(position.x, position.y - 1);
    this.sprite.setPosition(position.x, position.y).setDepth(Depth.bySortY(position.y));
  }
}
