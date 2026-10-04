import type { Blueprint } from '../entities/Blueprint';
import { Building } from '../entities/Building';
import type { Obstacle } from '../entities/Obstacle';
import type { Intent } from '../entities/Player';
import type { WorldEvent } from '../events';
import { Rules } from '../rules';
import { Position } from '../value-objects/Position';
import type { Work } from './Work';
import type { WorldState } from './WorldState';

export type ConstructionOrderResult =
  | { readonly ok: true; readonly building: Building }
  | { readonly ok: false; readonly reason: 'not-enough-wood' | 'blocked' };

type ConstructIntent = Extract<Intent, { kind: 'construct' }>;

/** Paying for buildings, placing their sites and hammering them until they are finished. */
export const Construction = {
  /** Whether a building with this blueprint fits at `position` without overlapping anything. */
  canPlace(state: WorldState, blueprint: Blueprint, position: Position): boolean {
    const radius = blueprint.footprintRadius;
    const { player } = state;
    const overlapsPlayer = position.distanceTo(player.position) < radius + player.radius;
    const overlapsItem = [...state.items.values()].some((item) => position.distanceTo(item.position) < radius);

    return state.isInside(position, radius) && !state.isBlocked(position, radius) && !overlapsPlayer && !overlapsItem;
  },

  /** Charges the wood and places the construction site. */
  place(state: WorldState, blueprint: Blueprint, position: Position): ConstructionOrderResult {
    if (state.player.inventory.wood < blueprint.woodCost) return { ok: false, reason: 'not-enough-wood' };
    if (!Construction.canPlace(state, blueprint, position)) return { ok: false, reason: 'blocked' };

    state.player.inventory.spendWood(blueprint.woodCost);
    const building = new Building(state.nextId('building'), blueprint, position);
    state.buildings.set(building.id, building);
    return { ok: true, building };
  },

  intervalMs: Rules.HAMMER_INTERVAL_MS,

  target(state: WorldState, intent: ConstructIntent): Obstacle | undefined {
    const building = state.buildings.get(intent.buildingId);
    return building && !building.isComplete ? building.footprint : undefined;
  },

  /** In front of the building (south), where the player stays in view. */
  preferredSpots(target: Obstacle, distance: number): Position[] {
    return [new Position(target.position.x, target.position.y + distance)];
  },

  impact(state: WorldState, intent: ConstructIntent, events: WorldEvent[]): boolean {
    const building = state.buildings.get(intent.buildingId);
    if (!building) return true;

    building.hammer();
    events.push({ type: 'building-hammered', buildingId: building.id, progress: building.progress });
    if (!building.isComplete) return false;

    events.push({ type: 'building-completed', buildingId: building.id });
    return true;
  },
} satisfies Work<ConstructIntent> & Record<string, unknown>;
