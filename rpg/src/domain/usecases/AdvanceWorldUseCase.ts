import type { GameEvent } from '../events';
import type { GameNotice } from './models/GameNotice';
import { toNotice } from './models/mappers';
import type { GameSessionRepository } from '../repositories/GameSessionRepository';

export class AdvanceWorldUseCase {
  private readonly sessions: GameSessionRepository;

  constructor(sessions: GameSessionRepository) {
    this.sessions = sessions;
  }

  /** Advances the simulation by `deltaMs` and returns what happened, including completed quests. */
  execute(deltaMs: number): GameNotice[] {
    const { world, quests } = this.sessions.current();
    const events: GameEvent[] = [...world.advance(deltaMs), ...quests.update(world)];
    return events.map((event) => toNotice(event, world));
  }
}
