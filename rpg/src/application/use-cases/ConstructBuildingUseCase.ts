import { Blueprints } from '../../domain/entities/Blueprint';
import { Position } from '../../domain/value-objects/Position';
import type { BlueprintKey, BuildingDto } from '../dto';
import { toBlueprintId, toBlueprintKey, toPoint } from '../mappers';
import type { GameSessionRepository } from '../ports/GameSessionRepository';

export type ConstructBuildingResult =
  | { readonly ok: true; readonly building: BuildingDto }
  | { readonly ok: false; readonly reason: 'not-enough-wood' | 'blocked' };

export class ConstructBuildingUseCase {
  private readonly sessions: GameSessionRepository;

  constructor(sessions: GameSessionRepository) {
    this.sessions = sessions;
  }

  /** Whether the site is free, so the adapter can preview the placement before committing. */
  canPlace(blueprint: BlueprintKey, x: number, y: number): boolean {
    return this.sessions.current().world.canPlace(Blueprints[toBlueprintId(blueprint)], new Position(x, y));
  }

  execute(blueprint: BlueprintKey, x: number, y: number): ConstructBuildingResult {
    const world = this.sessions.current().world;
    const result = world.orderConstruction(Blueprints[toBlueprintId(blueprint)], new Position(x, y));
    if (!result.ok) return result;

    const { building } = result;
    return {
      ok: true,
      building: {
        id: building.id,
        blueprintId: toBlueprintKey(building.blueprint.id),
        position: toPoint(building.position),
        progress: building.progress,
      },
    };
  }
}
