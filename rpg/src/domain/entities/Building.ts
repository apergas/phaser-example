import type { Position } from '../value-objects/Position';
import type { Blueprint } from './Blueprint';
import { Obstacle } from './Obstacle';

/** A building placed in the world. It blocks movement from the moment construction starts. */
export class Building {
  readonly id: string;
  readonly blueprint: Blueprint;
  readonly footprint: Obstacle;
  private hitsDone = 0;

  constructor(id: string, blueprint: Blueprint, position: Position) {
    this.id = id;
    this.blueprint = blueprint;
    this.footprint = new Obstacle(position, blueprint.footprintRadius);
  }

  get position(): Position {
    return this.footprint.position;
  }

  /** Construction progress from 0 (just started) to 1 (complete). */
  get progress(): number {
    return this.hitsDone / this.blueprint.hitsToBuild;
  }

  get isComplete(): boolean {
    return this.hitsDone >= this.blueprint.hitsToBuild;
  }

  hammer(): void {
    if (!this.isComplete) this.hitsDone += 1;
  }
}
