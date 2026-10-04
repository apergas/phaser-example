import type { Activity, Intent } from '../entities/Player';
import type { WorldEvent } from '../events';
import { Rules } from '../rules';
import type { Position } from '../value-objects/Position';
import { type WorkRegistry, workFor } from './Work';
import type { WorldState } from './WorldState';

/** Extra distance, beyond touching footprints, from which the player can still work on a target. */
const REACH_TOLERANCE = 6;

/** Walking, collisions and getting into position to work on a target. */
export class Navigation {
  private readonly state: WorldState;
  private readonly registry: WorkRegistry;

  constructor(state: WorldState, registry: WorkRegistry) {
    this.state = state;
    this.registry = registry;
  }

  /** Sends the player towards `destination`, clamped so its footprint stays inside the world. */
  walkTo(destination: Position): void {
    const { player } = this.state;
    player.walkTo(this.state.clamp(destination, player.radius));
  }

  /** Walks up to the intent's target, or starts working right away if it is already within reach. */
  goWorkOn(intent: Intent): void {
    if (this.isWithinReach(intent)) return this.startWork(intent);
    this.state.player.walkTo(this.workSpot(intent), intent);
  }

  step(deltaMs: number, activity: Extract<Activity, { kind: 'walking' }>, events: WorldEvent[]): void {
    const { player } = this.state;
    const next = player.nextPosition(deltaMs);
    if (!next) return;

    if (this.state.isBlocked(next, player.radius)) {
      if (activity.intent && this.isWithinReach(activity.intent)) return this.startWork(activity.intent);
      if (activity.intent) events.push({ type: 'player-blocked' });
      return player.stop();
    }

    player.placeAt(next);
    if (!next.equals(activity.destination)) return;
    if (activity.intent) this.startWork(activity.intent);
    else player.stop();
  }

  private startWork(intent: Intent): void {
    if (workFor(this.registry, intent).target(this.state, intent)) this.state.player.startWork(intent);
    else this.state.player.stop();
  }

  private isWithinReach(intent: Intent): boolean {
    const target = workFor(this.registry, intent).target(this.state, intent);
    if (!target) return false;

    const reach = target.radius + this.state.player.radius + Rules.WORK_GAP + REACH_TOLERANCE;
    return this.state.player.position.distanceTo(target.position) <= reach;
  }

  /**
   * Where to stand to work: the work's preferred spots first, falling back to the closest point on
   * the player's side when those are blocked or outside the world.
   */
  private workSpot(intent: Intent): Position {
    const { player } = this.state;
    const work = workFor(this.registry, intent);
    const target = work.target(this.state, intent);
    if (!target) return player.position;

    const distance = target.radius + player.radius + Rules.WORK_GAP;
    const side = player.position.x < target.position.x ? -1 : 1;
    const isFree = (spot: Position) =>
      this.state.isInside(spot, player.radius) && !this.state.isBlocked(spot, player.radius);

    const fallback = target.position.pointAtDistance(distance, player.position);
    return work.preferredSpots(target, distance, side).find(isFree) ?? this.state.clamp(fallback, player.radius);
  }
}
