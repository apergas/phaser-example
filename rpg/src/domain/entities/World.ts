import { Position } from '../value-objects/Position';
import type { Obstacle } from './Obstacle';
import type { Player } from './Player';

/** Aggregate that owns the player and the static obstacles, and enforces movement rules. */
export class World {
  readonly width: number;
  readonly height: number;
  readonly player: Player;
  readonly obstacles: readonly Obstacle[];

  constructor(width: number, height: number, player: Player, obstacles: readonly Obstacle[]) {
    if (width <= 0 || height <= 0) throw new Error('World size must be positive');
    this.width = width;
    this.height = height;
    this.player = player;
    this.obstacles = obstacles;
  }

  /** Sends the player towards `destination`, clamped so its footprint stays inside the world. */
  movePlayerTo(destination: Position): void {
    const radius = this.player.radius;
    const clamp = (value: number, max: number) => Math.min(Math.max(value, radius), max - radius);

    this.player.moveTo(new Position(clamp(destination.x, this.width), clamp(destination.y, this.height)));
  }

  advance(deltaMs: number): void {
    const next = this.player.nextPosition(deltaMs);
    if (!next) return;

    if (this.obstacles.some((obstacle) => obstacle.blocks(next, this.player.radius))) {
      this.player.stop();
      return;
    }

    this.player.placeAt(next);
  }
}
