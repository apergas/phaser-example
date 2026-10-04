import type { GameSession, GameSessionRepository } from '../../domain/repositories/GameSessionRepository';

/** Keeps the session in memory for the lifetime of the page. A save-game adapter would persist it. */
export class InMemoryGameSessionRepository implements GameSessionRepository {
  private session: GameSession | null = null;

  current(): GameSession {
    if (!this.session) throw new Error('No game in progress: run StartGameUseCase first');
    return this.session;
  }

  save(session: GameSession): void {
    this.session = session;
  }
}
