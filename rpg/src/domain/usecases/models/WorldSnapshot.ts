import type { BlueprintKey, ToolKey } from './keys';
import type { Point } from './Point';

export interface TreeInfo {
  readonly id: string;
  readonly position: Point;
}

export interface GroundItemInfo {
  readonly id: string;
  readonly kind: ToolKey;
  readonly position: Point;
}

export interface BuildingInfo {
  readonly id: string;
  readonly blueprintId: BlueprintKey;
  readonly position: Point;
  readonly progress: number;
}

/** Everything placed in the world at a given moment, to draw it from scratch. */
export interface WorldSnapshot {
  readonly width: number;
  readonly height: number;
  readonly trees: readonly TreeInfo[];
  readonly items: readonly GroundItemInfo[];
  readonly buildings: readonly BuildingInfo[];
}
