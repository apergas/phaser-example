import type { GameSessionRepository } from '../ports/GameSessionRepository';

export type ChopTreeResult = 'ok' | 'no-axe' | 'unknown-tree';

export class ChopTreeUseCase {
  private readonly sessions: GameSessionRepository;

  constructor(sessions: GameSessionRepository) {
    this.sessions = sessions;
  }

  execute(treeId: string): ChopTreeResult {
    return this.sessions.current().world.orderChop(treeId);
  }
}
