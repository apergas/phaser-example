/**
 * Read-only data handed to adapters. Adapters depend on these types only, never on domain ones;
 * `mappers.ts` converts between both and the compiler checks the two stay in sync.
 */

export type ToolKey = 'axe';
export type BlueprintKey = 'house';
export type QuestKey = 'pick-up-axe' | 'gather-wood' | 'build-house';

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
  readonly blueprintId: BlueprintKey;
  readonly woodCost: number;
  readonly affordable: boolean;
}

export interface TreeDto {
  readonly id: string;
  readonly position: PointDto;
}

export interface GroundItemDto {
  readonly id: string;
  readonly kind: ToolKey;
  readonly position: PointDto;
}

export interface BuildingDto {
  readonly id: string;
  readonly blueprintId: BlueprintKey;
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
  readonly id: QuestKey;
  readonly progress: number;
  readonly target: number;
  readonly completed: boolean;
  /** The first unfinished quest: what the player should do next. */
  readonly current: boolean;
}

/** What happened during a simulation step, for adapters to animate or announce. */
export type GameEventDto =
  | { readonly type: 'item-picked-up'; readonly itemId: string; readonly kind: ToolKey }
  | { readonly type: 'player-blocked' }
  | { readonly type: 'tree-hit'; readonly treeId: string; readonly hitsRemaining: number }
  | { readonly type: 'tree-felled'; readonly treeId: string; readonly wood: number }
  | { readonly type: 'building-hammered'; readonly buildingId: string; readonly progress: number }
  | { readonly type: 'building-completed'; readonly buildingId: string; readonly blueprintId: BlueprintKey }
  | { readonly type: 'quest-completed'; readonly questId: QuestKey };
