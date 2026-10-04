import type { BlueprintId } from '../domain/entities/Blueprint';
import type { ToolKind } from '../domain/entities/Inventory';
import type { QuestId } from '../domain/quests/QuestLog';

/** Read-only data handed to adapters, so they never touch domain entities directly. */

export interface PointDto {
  readonly x: number;
  readonly y: number;
}

export type ActivityKind = 'idle' | 'walking' | 'chopping' | 'constructing';

export interface PlayerStateDto {
  readonly position: PointDto;
  readonly activity: ActivityKind;
  /** What the player is walking to or working on, if anything. */
  readonly target: PointDto | null;
  /** Progress of the current swing, 0..1, when chopping or constructing. */
  readonly swingProgress: number;
  readonly wood: number;
  readonly hasAxe: boolean;
}

export interface BuildOptionDto {
  readonly blueprintId: BlueprintId;
  readonly woodCost: number;
  readonly affordable: boolean;
}

export interface TreeDto {
  readonly id: string;
  readonly position: PointDto;
}

export interface GroundItemDto {
  readonly id: string;
  readonly kind: ToolKind;
  readonly position: PointDto;
}

export interface BuildingDto {
  readonly id: string;
  readonly blueprintId: BlueprintId;
  readonly position: PointDto;
  readonly progress: number;
}

export interface WorldSnapshotDto {
  readonly width: number;
  readonly height: number;
  readonly trees: readonly TreeDto[];
  readonly items: readonly GroundItemDto[];
  readonly buildings: readonly BuildingDto[];
}

export interface QuestDto {
  readonly id: QuestId;
  readonly progress: number;
  readonly target: number;
  readonly completed: boolean;
  /** The first unfinished quest: what the player should do next. */
  readonly current: boolean;
}
