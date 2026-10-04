import type { GameEvent } from '../../domain/events';
import type { GameEventDto } from '../dto';
import { toEventDto } from '../mappers';
import type { GameSessionRepository } from '../ports/GameSessionRepository';

export class AdvanceWorldUseCase {
  private readonly sessions: GameSessionRepository;

  constructor(sessions: GameSessionRepository) {
    this.sessions = sessions;
  }

  /** Advances the simulation by `deltaMs` and returns what happened, including completed quests. */
  execute(deltaMs: number): GameEventDto[] {
    const { world, quests } = this.sessions.current();
    const events: GameEvent[] = [...world.advance(deltaMs), ...quests.update(world)];
    return events.map((event) => toEventDto(event, world));
  }
}
