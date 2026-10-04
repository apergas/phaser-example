import type { Position } from '../value-objects/Position';
import { Inventory } from './Inventory';

/** Work the player is asked to do on a target: walk up to it, then work until it is done. */
export type Intent =
  | { readonly kind: 'chop'; readonly treeId: string }
  | { readonly kind: 'construct'; readonly buildingId: string };

export type IntentKind = Intent['kind'];

export type Activity =
  | { readonly kind: 'idle' }
  | { readonly kind: 'walking'; readonly destination: Position; readonly intent: Intent | null }
  /** `elapsedMs` is the time since the last impact (axe hit, hammer blow...). */
  | { readonly kind: 'working'; readonly intent: Intent; readonly elapsedMs: number };

export class Player {
  /** Movement speed in world units per second. */
  readonly speed: number;
  /** Radius of the player's footprint on the ground, used for collisions. */
  readonly radius: number;
  readonly inventory = new Inventory();
  private currentPosition: Position;
  private currentActivity: Activity = { kind: 'idle' };

  constructor(position: Position, speed: number, radius: number) {
    if (speed <= 0) throw new Error('Player speed must be positive');
    if (radius <= 0) throw new Error('Player radius must be positive');
    this.currentPosition = position;
    this.speed = speed;
    this.radius = radius;
  }

  get position(): Position {
    return this.currentPosition;
  }

  get activity(): Activity {
    return this.currentActivity;
  }

  get isMoving(): boolean {
    return this.currentActivity.kind === 'walking';
  }

  walkTo(destination: Position, intent: Intent | null = null): void {
    this.currentActivity = { kind: 'walking', destination, intent };
  }

  startWork(intent: Intent): void {
    this.currentActivity = { kind: 'working', intent, elapsedMs: 0 };
  }

  /** Keeps working on the current task; `elapsedMs` is the time since the last impact. */
  continueWork(elapsedMs: number): void {
    if (this.currentActivity.kind === 'working') this.currentActivity = { ...this.currentActivity, elapsedMs };
  }

  stop(): void {
    this.currentActivity = { kind: 'idle' };
  }

  /** Where the player would be after `deltaMs`, or null when not walking. Does not mutate state. */
  nextPosition(deltaMs: number): Position | null {
    if (this.currentActivity.kind !== 'walking') return null;

    const step = (this.speed * deltaMs) / 1000;
    return this.currentPosition.moveTowards(this.currentActivity.destination, step);
  }

  placeAt(position: Position): void {
    this.currentPosition = position;
  }
}
