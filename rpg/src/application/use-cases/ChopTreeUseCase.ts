import type { ChopOrderResult, World } from '../../domain/entities/World';

export class ChopTreeUseCase {
  private readonly world: World;

  constructor(world: World) {
    this.world = world;
  }

  execute(treeId: string): ChopOrderResult {
    return this.world.orderChop(treeId);
  }
}
