import type { Position } from '../value-objects/Position';

export class Player {
  /** Movement speed in world units per second. */
  readonly speed: number;
  /** Radius of the player's footprint on the ground, used for collisions. */
  readonly radius: number;
  private currentPosition: Position;
  private destination: Position | null = null;

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

  get isMoving(): boolean {
    return this.destination !== null;
  }

  moveTo(destination: Position): void {
    this.destination = destination;
  }

  stop(): void {
    this.destination = null;
  }

  /** Where the player would be after `deltaMs`, or null when idle. Does not mutate state. */
  nextPosition(deltaMs: number): Position | null {
    if (!this.destination) return null;

    const step = (this.speed * deltaMs) / 1000;
    return this.currentPosition.moveTowards(this.destination, step);
  }

  placeAt(position: Position): void {
    this.currentPosition = position;

    if (this.destination && position.equals(this.destination)) {
      this.destination = null;
    }
  }
}
