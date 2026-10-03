import type { World } from '../../domain/entities/World';
import { Position } from '../../domain/value-objects/Position';

export class MovePlayerToUseCase {
  private readonly world: World;

  constructor(world: World) {
    this.world = world;
  }

  execute(x: number, y: number): void {
    this.world.movePlayerTo(new Position(x, y));
  }
}
