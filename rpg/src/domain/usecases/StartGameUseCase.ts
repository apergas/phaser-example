import { QuestLog } from '../quests/QuestLog';
import type { GameSessionRepository } from '../repositories/GameSessionRepository';
import type { LevelRepository } from '../repositories/LevelRepository';

/** Starts a fresh game in the level's world and makes it the current session. */
export class StartGameUseCase {
  private readonly levels: LevelRepository;
  private readonly sessions: GameSessionRepository;

  constructor(levels: LevelRepository, sessions: GameSessionRepository) {
    this.levels = levels;
    this.sessions = sessions;
  }

  execute(): void {
    this.sessions.save({ world: this.levels.load(), quests: new QuestLog() });
  }
}
