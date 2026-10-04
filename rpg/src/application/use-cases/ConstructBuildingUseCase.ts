import { type BlueprintId, Blueprints } from '../../domain/entities/Blueprint';
import type { World } from '../../domain/entities/World';
import { Position } from '../../domain/value-objects/Position';
import type { BuildingDto } from '../dto';

export type ConstructBuildingResult =
  | { readonly ok: true; readonly building: BuildingDto }
  | { readonly ok: false; readonly reason: 'not-enough-wood' | 'blocked' };

export class ConstructBuildingUseCase {
  private readonly world: World;

  constructor(world: World) {
    this.world = world;
  }

  /** Whether the site is free, so the adapter can preview the placement before committing. */
  canPlace(blueprintId: BlueprintId, x: number, y: number): boolean {
    return this.world.canPlace(Blueprints[blueprintId], new Position(x, y));
  }

  execute(blueprintId: BlueprintId, x: number, y: number): ConstructBuildingResult {
    const result = this.world.orderConstruction(Blueprints[blueprintId], new Position(x, y));
    if (!result.ok) return result;

    const { building } = result;
    return {
      ok: true,
      building: {
        id: building.id,
        blueprintId: building.blueprint.id,
        position: { x: building.position.x, y: building.position.y },
        progress: building.progress,
      },
    };
  }
}
