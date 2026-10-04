import type * as Phaser from 'phaser';
import type { PlayerStateDto, PointDto } from '../../../application/dto';
import { CHARACTER_ORIGIN_Y, type FacingDirection, FACING_DIRECTIONS, WorkSheet, WorkSheets } from '../assets';
import { Depth } from './depth';

export function heroAnimationKey(state: 'walk' | 'idle', direction: FacingDirection, withAxe: boolean): string {
  return `hero-${state}-${direction}${withAxe ? '-axe' : ''}`;
}

/**
 * Visual representation of the player. Knows how to draw, not how to move. Origin = feet.
 * Walking and idle play looping animations; work (chopping, hammering) is driven frame by frame
 * from the domain's swing progress, so the impact frame lines up with the actual hit.
 */
export class PlayerView {
  private readonly shadow: Phaser.GameObjects.Ellipse;
  private readonly sprite: Phaser.GameObjects.Sprite;
  private lastPosition: PointDto;
  private facing: FacingDirection = 'down';

  constructor(scene: Phaser.Scene, initial: PointDto) {
    this.shadow = scene.add.ellipse(0, 0, 22, 7, 0x000000, 0.3).setDepth(Depth.SHADOW);
    this.sprite = scene.add.sprite(initial.x, initial.y, WorkSheets.CHOP.key);
    this.lastPosition = initial;
  }

  /** Game object the camera should follow. */
  get followTarget(): Phaser.GameObjects.Sprite {
    return this.sprite;
  }

  render(state: PlayerStateDto): void {
    const { position } = state;
    const dx = position.x - this.lastPosition.x;
    const dy = position.y - this.lastPosition.y;
    this.lastPosition = position;

    if (state.activity === 'chopping' || state.activity === 'constructing') {
      if (state.target) this.facing = facingFor(state.target.x - position.x, state.target.y - position.y);
      this.showWorkFrame(state.activity, state.swingProgress);
    } else {
      const isWalking = dx !== 0 || dy !== 0;
      if (isWalking) this.facing = facingFor(dx, dy);
      this.sprite.setOrigin(0.5, CHARACTER_ORIGIN_Y);
      this.sprite.anims.play(heroAnimationKey(isWalking ? 'walk' : 'idle', this.facing, state.hasAxe), true);
    }

    this.shadow.setPosition(position.x, position.y - 1);
    this.sprite.setPosition(position.x, position.y).setDepth(Depth.bySortY(position.y));
  }

  private showWorkFrame(activity: 'chopping' | 'constructing', swingProgress: number): void {
    const [sheet, sequence] =
      activity === 'chopping'
        ? [WorkSheets.CHOP, WorkSheet.CHOP_SEQUENCE]
        : [WorkSheets.HAMMER, WorkSheet.HAMMER_SEQUENCE];
    const step = Math.min(sequence.length - 1, Math.floor(swingProgress * sequence.length));
    const row = FACING_DIRECTIONS.indexOf(this.facing);

    this.sprite.anims.stop();
    this.sprite.setTexture(sheet.key, row * WorkSheet.COLUMNS + sequence[step]);
    this.sprite.setOrigin(0.5, WorkSheet.ORIGIN_Y);
  }
}

function facingFor(dx: number, dy: number): FacingDirection {
  if (Math.abs(dx) > Math.abs(dy)) return dx < 0 ? 'left' : 'right';
  return dy < 0 ? 'up' : 'down';
}
