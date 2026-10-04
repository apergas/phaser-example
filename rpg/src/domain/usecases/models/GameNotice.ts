import type { BlueprintKey, QuestKey, ToolKey } from './keys';

/**
 * What happened during a simulation step, as reported to adapters so they can animate or announce
 * it. Built from domain events, plus whatever adapters need that the event itself does not carry.
 */
export type GameNotice =
  | { readonly type: 'item-picked-up'; readonly itemId: string; readonly kind: ToolKey }
  | { readonly type: 'player-blocked' }
  | { readonly type: 'tree-hit'; readonly treeId: string; readonly hitsRemaining: number }
  | { readonly type: 'tree-felled'; readonly treeId: string; readonly wood: number }
  | { readonly type: 'building-hammered'; readonly buildingId: string; readonly progress: number }
  | { readonly type: 'building-completed'; readonly buildingId: string; readonly blueprintId: BlueprintKey }
  | { readonly type: 'quest-completed'; readonly questId: QuestKey };
