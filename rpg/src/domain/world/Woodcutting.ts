import type { Obstacle } from '../entities/Obstacle';
import type { Intent } from '../entities/Player';
import type { WorldEvent } from '../events';
import { Rules } from '../rules';
import { Position } from '../value-objects/Position';
import type { Work } from './Work';
import type { WorldState } from './WorldState';

export type ChopOrderResult = 'ok' | 'no-axe' | 'unknown-tree';

type ChopIntent = Extract<Intent, { kind: 'chop' }>;

/** Felling trees with an axe: one hit per interval, wood added when the tree falls. */
export const Woodcutting = {
  check(state: WorldState, treeId: string): ChopOrderResult {
    if (!state.trees.has(treeId)) return 'unknown-tree';
    if (!state.player.inventory.hasTool('axe')) return 'no-axe';
    return 'ok';
  },

  intervalMs: Rules.CHOP_INTERVAL_MS,

  target(state: WorldState, intent: ChopIntent): Obstacle | undefined {
    return state.trees.get(intent.treeId)?.footprint;
  },

  /** Beside the trunk, a pixel in front so the player is drawn over it; near side first. */
  preferredSpots(target: Obstacle, distance: number, side: -1 | 1): Position[] {
    const { x, y } = target.position;
    return [new Position(x + side * distance, y + 1), new Position(x - side * distance, y + 1)];
  },

  impact(state: WorldState, intent: ChopIntent, events: WorldEvent[]): boolean {
    const tree = state.trees.get(intent.treeId);
    if (!tree) return true;

    tree.hit();
    events.push({ type: 'tree-hit', treeId: tree.id, hitsRemaining: tree.hitsRemaining });
    if (!tree.isFelled) return false;

    state.trees.delete(tree.id);
    state.player.inventory.addWood(tree.woodYield);
    events.push({ type: 'tree-felled', treeId: tree.id, wood: tree.woodYield });
    return true;
  },
} satisfies Work<ChopIntent> & Record<string, unknown>;
