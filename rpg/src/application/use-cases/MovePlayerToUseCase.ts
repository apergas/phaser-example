import { Position } from '../../domain/value-objects/Position';
import type { GameSessionRepository } from '../ports/GameSessionRepository';

export class MovePlayerToUseCase {
  private readonly sessions: GameSessionRepository;

  constructor(sessions: GameSessionRepository) {
    this.sessions = sessions;
  }

  execute(x: number, y: number): void {
    this.sessions.current().world.movePlayerTo(new Position(x, y));
  }
}
