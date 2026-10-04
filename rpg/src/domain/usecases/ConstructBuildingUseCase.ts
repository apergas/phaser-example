import { Blueprints } from '../entities/Blueprint';
import { Position } from '../value-objects/Position';
import type { BuildingInfo } from './models/WorldSnapshot';
import type { BlueprintKey } from './models/keys';
import { toBlueprintId, toBlueprintKey, toPoint } from './models/mappers';
import type { GameSessionRepository } from '../repositories/GameSessionRepository';

export type ConstructBuildingResult =
  | { readonly ok: true; readonly building: BuildingInfo }
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
