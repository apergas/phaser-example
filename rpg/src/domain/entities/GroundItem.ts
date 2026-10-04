import type { Position } from '../value-objects/Position';
import type { ToolKind } from './Inventory';

/** A tool lying on the ground, waiting to be picked up. */
export class GroundItem {
  readonly id: string;
  readonly kind: ToolKind;
  readonly position: Position;

  constructor(id: string, kind: ToolKind, position: Position) {
    this.id = id;
    this.kind = kind;
    this.position = position;
  }
}
