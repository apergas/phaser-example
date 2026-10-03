import type { Position } from '../value-objects/Position';

/** Something solid on the ground (tree trunk, rock...). Only its circular footprint matters. */
export class Obstacle {
  readonly position: Position;
  readonly radius: number;

  constructor(position: Position, radius: number) {
    if (radius <= 0) throw new Error('Obstacle radius must be positive');
    this.position = position;
    this.radius = radius;
  }

  blocks(position: Position, radius: number): boolean {
    return this.position.distanceTo(position) < this.radius + radius;
  }
}
