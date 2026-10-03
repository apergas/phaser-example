import type { World } from '../../domain/entities/World';
import type { Position } from '../../domain/value-objects/Position';

export class AdvanceWorldUseCase {
  private readonly world: World;

  constructor(world: World) {
    this.world = world;
  }

  /** Advances the simulation by `deltaMs` and returns the resulting player position. */
  execute(deltaMs: number): Position {
    this.world.advance(deltaMs);
    return this.world.player.position;
  }
}
