import type { Obstacle } from '../entities/Obstacle';
import type { Intent, IntentKind } from '../entities/Player';
import type { WorldEvent } from '../events';
import type { Position } from '../value-objects/Position';
import type { WorldState } from './WorldState';

/**
 * A kind of work the player does on a target, one impact at a time (chopping, constructing...).
 * Adding a mechanic means adding an `Intent` variant and registering a `Work` for it in `World`;
 * movement, reach and timing are handled generically.
 */
export interface Work<I extends Intent = Intent> {
  /** Time between two impacts. */
  readonly intervalMs: number;
  /** The footprint being worked on, or undefined when it no longer exists. */
  target(state: WorldState, intent: I): Obstacle | undefined;
  /**
   * Where the player prefers to stand, best first, `distance` away from the target's centre.
   * `side` is -1 when the player approaches from the left, 1 from the right.
   */
  preferredSpots(target: Obstacle, distance: number, side: -1 | 1): Position[];
  /** Applies one impact. Returns true when the work is finished. */
  impact(state: WorldState, intent: I, events: WorldEvent[]): boolean;
}

export type WorkRegistry = { readonly [K in IntentKind]: Work<Extract<Intent, { kind: K }>> };

/** The registered work for an intent, typed for the general case. */
export function workFor(registry: WorkRegistry, intent: Intent): Work {
  return registry[intent.kind] as unknown as Work;
}
