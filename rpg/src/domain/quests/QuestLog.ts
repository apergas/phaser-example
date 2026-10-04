import type { World } from '../world/World';
import type { QuestEvent } from '../events';

export type QuestId = 'pick-up-axe' | 'gather-wood' | 'build-house';

/** A goal measured against the world: done once `progress` reaches `target`. */
export interface Quest {
  readonly id: QuestId;
  readonly target: number;
  progress(world: World): number;
}

export const Quests: readonly Quest[] = [
  { id: 'pick-up-axe', target: 1, progress: (world) => (world.player.inventory.hasTool('axe') ? 1 : 0) },
  { id: 'gather-wood', target: 15, progress: (world) => world.player.inventory.wood },
  {
    id: 'build-house',
    target: 1,
    progress: (world) =>
      world.buildings.filter((building) => building.isComplete && building.blueprint.id === 'house').length,
  },
];

export interface QuestStatus {
  readonly id: QuestId;
  readonly progress: number;
  readonly target: number;
  readonly completed: boolean;
}

/**
 * Tracks which quests are done. Completion is permanent: spending the wood afterwards does not
 * undo "gather wood". Quests can be completed in any order.
 */
export class QuestLog {
  private readonly quests: readonly Quest[];
  private readonly completed = new Set<QuestId>();

  constructor(quests: readonly Quest[] = Quests) {
    this.quests = quests;
  }

  /** Marks newly fulfilled quests as completed and reports them. */
  update(world: World): QuestEvent[] {
    const events: QuestEvent[] = [];
    for (const quest of this.quests) {
      if (this.completed.has(quest.id) || quest.progress(world) < quest.target) continue;
      this.completed.add(quest.id);
      events.push({ type: 'quest-completed', questId: quest.id });
    }
    return events;
  }

  status(world: World): QuestStatus[] {
    return this.quests.map((quest) => {
      const completed = this.completed.has(quest.id);
      const progress = completed ? quest.target : Math.min(quest.progress(world), quest.target);
      return { id: quest.id, progress, target: quest.target, completed };
    });
  }
}
