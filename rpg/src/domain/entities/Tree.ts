import type { Position } from '../value-objects/Position';
import { Obstacle } from './Obstacle';

/** A choppable tree. Its trunk blocks movement until it is felled. */
export class Tree {
  readonly id: string;
  readonly footprint: Obstacle;
  /** Wood added to the inventory when the tree is felled. */
  readonly woodYield: number;
  readonly hitsToFell: number;
  private hitsTaken = 0;

  constructor(id: string, position: Position, trunkRadius: number, woodYield: number, hitsToFell: number) {
    if (woodYield < 0) throw new Error('Wood yield cannot be negative');
    if (hitsToFell <= 0) throw new Error('A tree needs at least one hit to fell');
    this.id = id;
    this.footprint = new Obstacle(position, trunkRadius);
    this.woodYield = woodYield;
    this.hitsToFell = hitsToFell;
  }

  get position(): Position {
    return this.footprint.position;
  }

  get hitsRemaining(): number {
    return this.hitsToFell - this.hitsTaken;
  }

  get isFelled(): boolean {
    return this.hitsRemaining === 0;
  }

  hit(): void {
    if (!this.isFelled) this.hitsTaken += 1;
  }
}
