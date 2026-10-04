import { GroundItem } from '../../domain/entities/GroundItem';
import type { ToolKind } from '../../domain/entities/Inventory';
import { Player } from '../../domain/entities/Player';
import { Tree } from '../../domain/entities/Tree';
import { Rules } from '../../domain/rules';
import { Position } from '../../domain/value-objects/Position';
import { World } from '../../domain/world/World';
import type { LevelDto, PointDto } from '../dtos/LevelDto';

const TOOL_KINDS: readonly ToolKind[] = ['axe'];

/** Turns level data into a ready-to-play world, rejecting data the domain cannot represent. */
export function toWorld(level: LevelDto): World {
  return new World(
    level.width,
    level.height,
    new Player(toPosition(level.playerStart), Rules.PLAYER_SPEED, Rules.PLAYER_RADIUS),
    level.trees.map(
      (tree) => new Tree(tree.id, toPosition(tree), Rules.TREE_TRUNK_RADIUS, tree.wood, Rules.HITS_TO_FELL_TREE),
    ),
    level.items.map((item) => new GroundItem(item.id, toToolKind(item.kind, item.id), toPosition(item))),
  );
}

function toPosition(point: PointDto): Position {
  return new Position(point.x, point.y);
}

function toToolKind(kind: string, itemId: string): ToolKind {
  const tool = TOOL_KINDS.find((candidate) => candidate === kind);
  if (!tool) throw new Error(`Level item "${itemId}" has an unknown kind: "${kind}"`);
  return tool;
}
