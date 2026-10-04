import type { World } from '../../domain/entities/World';
import type { GameEvent } from '../../domain/events';
import type { QuestLog } from '../../domain/quests/QuestLog';

export class AdvanceWorldUseCase {
  private readonly world: World;
  private readonly questLog: QuestLog;

  constructor(world: World, questLog: QuestLog) {
    this.world = world;
    this.questLog = questLog;
  }

  /** Advances the simulation by `deltaMs` and returns what happened, including completed quests. */
  execute(deltaMs: number): GameEvent[] {
    const events: GameEvent[] = this.world.advance(deltaMs);
    return [...events, ...this.questLog.update(this.world)];
  }
}
