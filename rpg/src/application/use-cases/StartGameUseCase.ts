import { GroundItem } from '../../domain/entities/GroundItem';
import { Player } from '../../domain/entities/Player';
import { Tree } from '../../domain/entities/Tree';
import { QuestLog } from '../../domain/quests/QuestLog';
import { Rules } from '../../domain/rules';
import { Position } from '../../domain/value-objects/Position';
import { World } from '../../domain/world/World';
import { toToolKind } from '../mappers';
import type { GameSessionRepository } from '../ports/GameSessionRepository';
import type { LevelSource } from '../ports/LevelSource';

/** Builds a fresh game from a level and makes it the current session. */
export class StartGameUseCase {
  private readonly levels: LevelSource;
  private readonly sessions: GameSessionRepository;

  constructor(levels: LevelSource, sessions: GameSessionRepository) {
    this.levels = levels;
    this.sessions = sessions;
  }

  execute(): void {
    const level = this.levels.load();
    const at = (point: { x: number; y: number }) => new Position(point.x, point.y);

    const world = new World(
      level.width,
      level.height,
      new Player(at(level.playerStart), Rules.PLAYER_SPEED, Rules.PLAYER_RADIUS),
      level.trees.map((tree) => new Tree(tree.id, at(tree), Rules.TREE_TRUNK_RADIUS, tree.wood, Rules.HITS_TO_FELL_TREE)),
      level.items.map((item) => new GroundItem(item.id, toToolKind(item.kind), at(item))),
    );
    this.sessions.save({ world, quests: new QuestLog() });
  }
}
