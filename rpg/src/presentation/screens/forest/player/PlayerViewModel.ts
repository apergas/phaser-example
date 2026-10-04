import type { PlayerState } from '../../../../domain/usecases/models/PlayerState';
import type { Point } from '../../../../domain/usecases/models/Point';

export type Facing = 'up' | 'left' | 'down' | 'right';

/** Everything the player sprite needs to be drawn; no engine or art details. */
export interface PlayerRenderState {
  readonly position: Point;
  readonly facing: Facing;
  readonly pose:
    | { readonly kind: 'idle' | 'walk'; readonly withAxe: boolean }
    | { readonly kind: 'work'; readonly tool: 'axe' | 'hammer'; readonly swingProgress: number };
}

/**
 * Turns the player's state into what to draw: which way it faces and which pose it holds.
 * Facing follows the movement; while working it faces the target instead.
 */
export class PlayerViewModel {
  private lastPosition: Point | null = null;
  private facing: Facing = 'down';
  private current: PlayerRenderState | null = null;

  get state(): PlayerRenderState {
    if (!this.current) throw new Error('PlayerViewModel has not been updated yet');
    return this.current;
  }

  update(player: PlayerState): void {
    const { position } = player;
    const previous = this.lastPosition ?? position;
    const dx = position.x - previous.x;
    const dy = position.y - previous.y;
    this.lastPosition = position;

    const working = player.activity === 'chopping' || player.activity === 'constructing';
    if (working && player.target) this.facing = facingFor(player.target.x - position.x, player.target.y - position.y);
    else if (dx !== 0 || dy !== 0) this.facing = facingFor(dx, dy);

    const pose: PlayerRenderState['pose'] = working
      ? { kind: 'work', tool: player.activity === 'chopping' ? 'axe' : 'hammer', swingProgress: player.swingProgress }
      : { kind: dx !== 0 || dy !== 0 ? 'walk' : 'idle', withAxe: player.hasAxe };

    this.current = { position, facing: this.facing, pose };
  }
}

function facingFor(dx: number, dy: number): Facing {
  if (Math.abs(dx) > Math.abs(dy)) return dx < 0 ? 'left' : 'right';
  return dy < 0 ? 'up' : 'down';
}
