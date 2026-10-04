import type { ToolKind } from './entities/Inventory';
import type { QuestId } from './quests/QuestLog';

/** Things that happened while the world advanced, so adapters can react (animate, play sounds...). */
export type WorldEvent =
  | { readonly type: 'item-picked-up'; readonly itemId: string; readonly kind: ToolKind }
  /** Something stood between the player and the target it was sent to work on. */
  | { readonly type: 'player-blocked' }
  | { readonly type: 'tree-hit'; readonly treeId: string; readonly hitsRemaining: number }
  | { readonly type: 'tree-felled'; readonly treeId: string; readonly wood: number }
  | { readonly type: 'building-hammered'; readonly buildingId: string; readonly progress: number }
  | { readonly type: 'building-completed'; readonly buildingId: string };

export type QuestEvent = { readonly type: 'quest-completed'; readonly questId: QuestId };

/** Everything adapters may react to after a simulation step. */
export type GameEvent = WorldEvent | QuestEvent;
