import type { QuestLog } from '../quests/QuestLog';
import type { World } from '../world/World';

/** Everything that makes up a game in progress. */
export interface GameSession {
  readonly world: World;
  readonly quests: QuestLog;
}

/**
 * Where the current game lives. Use cases fetch the session on every call, so starting a new game
 * or loading a saved one only means storing a different session here.
 */
export interface GameSessionRepository {
  current(): GameSession;
  save(session: GameSession): void;
}
