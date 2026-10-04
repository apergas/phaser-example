import type { WorldEvent } from '../events';
import { Rules } from '../rules';
import type { WorldState } from './WorldState';

/** Picks up every item the player is standing on. */
export function pickUpItems(state: WorldState, events: WorldEvent[]): void {
  const { player } = state;
  for (const item of [...state.items.values()]) {
    if (item.position.distanceTo(player.position) > Rules.PICK_UP_RANGE) continue;

    state.items.delete(item.id);
    player.inventory.addTool(item.kind);
    events.push({ type: 'item-picked-up', itemId: item.id, kind: item.kind });
  }
}
