import type * as Phaser from 'phaser';
import type { Position } from '../../../domain/value-objects/Position';
import { CHARACTER_ORIGIN_Y, type FacingDirection, Sheets } from '../assets';
import { Depth } from './depth';

export function heroAnimationKey(state: 'walk' | 'idle', direction: FacingDirection): string {
  return `hero-${state}-${direction}`;
}

/**
 * Visual representation of the player. Knows how to draw, not how to move. Origin = feet.
 * Facing and walk/idle state are derived from how the position changed since the last frame.
 */
export class PlayerView {
  private readonly shadow: Phaser.GameObjects.Ellipse;
  private readonly sprite: Phaser.GameObjects.Sprite;
  private lastPosition: Position;
  private facing: FacingDirection = 'down';

  constructor(scene: Phaser.Scene, initial: Position) {
    this.shadow = scene.add.ellipse(0, 0, 22, 7, 0x000000, 0.3).setDepth(Depth.SHADOW);
    this.sprite = scene.add.sprite(0, 0, Sheets.HERO_IDLE.key).setOrigin(0.5, CHARACTER_ORIGIN_Y);
    this.lastPosition = initial;

    this.render(initial);
  }

  /** Game object the camera should follow. */
  get followTarget(): Phaser.GameObjects.Sprite {
    return this.sprite;
  }

  render(position: Position): void {
    const dx = position.x - this.lastPosition.x;
    const dy = position.y - this.lastPosition.y;
    const isWalking = dx !== 0 || dy !== 0;
    this.lastPosition = position;

    if (isWalking) this.facing = facingFor(dx, dy);
    this.sprite.anims.play(heroAnimationKey(isWalking ? 'walk' : 'idle', this.facing), true);

    this.shadow.setPosition(position.x, position.y - 1);
    this.sprite.setPosition(position.x, position.y).setDepth(Depth.bySortY(position.y));
  }
}

function facingFor(dx: number, dy: number): FacingDirection {
  if (Math.abs(dx) > Math.abs(dy)) return dx < 0 ? 'left' : 'right';
  return dy < 0 ? 'up' : 'down';
}
