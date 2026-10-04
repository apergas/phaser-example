import { GroundItem } from '../src/domain/entities/GroundItem';
import { Player } from '../src/domain/entities/Player';
import { Tree } from '../src/domain/entities/Tree';
import { QuestLog } from '../src/domain/quests/QuestLog';
import { World } from '../src/domain/world/World';
import { GameSessionRepositoryImpl } from '../src/data/repositories/GameSessionRepositoryImpl';
import { Rules } from '../src/domain/rules';
import { Position } from '../src/domain/value-objects/Position';

export const PLAYER_SPEED = 100;
export const PLAYER_RADIUS = 8;
export const TRUNK_RADIUS = 10;
export const WOOD_PER_TREE = 6;

export const createPlayer = (x = 100, y = 100) => new Player(new Position(x, y), PLAYER_SPEED, PLAYER_RADIUS);

export const createTree = (id: string, x: number, y: number) =>
  new Tree(id, new Position(x, y), TRUNK_RADIUS, WOOD_PER_TREE, Rules.HITS_TO_FELL_TREE);

export const createAxe = (x: number, y: number) => new GroundItem('axe-1', 'axe', new Position(x, y));

export const createWorld = (options: { player?: Player; trees?: Tree[]; items?: GroundItem[] } = {}) =>
  new World(1000, 1000, options.player ?? createPlayer(), options.trees ?? [], options.items ?? []);

/** Advances the world in 16ms steps, collecting every event. */
export function advanceFor(world: World, totalMs: number) {
  const events = [];
  for (let elapsed = 0; elapsed < totalMs; elapsed += 16) events.push(...world.advance(16));
  return events;
}

/** A session repository holding `world`, as the use cases expect it. */
export function sessionFor(world: World, quests = new QuestLog()) {
  const sessions = new GameSessionRepositoryImpl();
  sessions.save({ world, quests });
  return sessions;
}
