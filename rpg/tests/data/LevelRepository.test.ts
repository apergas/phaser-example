import { describe, expect, it } from 'vitest';
import { ProceduralForestLevelDataSource } from '../../src/data/datasources/ProceduralForestLevelDataSource';
import type { LevelDto } from '../../src/data/dtos/LevelDto';
import { toWorld } from '../../src/data/mappers/LevelMapper';
import { InMemoryGameSessionRepository } from '../../src/data/repositories/InMemoryGameSessionRepository';
import { LevelRepositoryImpl } from '../../src/data/repositories/LevelRepositoryImpl';
import { Rules } from '../../src/domain/rules';

const level: LevelDto = {
  width: 400,
  height: 300,
  playerStart: { x: 200, y: 150 },
  trees: [{ id: 'tree-a', x: 50, y: 60, wood: 5 }],
  items: [{ id: 'axe', kind: 'axe', x: 220, y: 150 }],
};

describe('LevelMapper', () => {
  it('builds the world with the domain tuning values', () => {
    const world = toWorld(level);

    expect(world.width).toBe(400);
    expect(world.player.position).toMatchObject({ x: 200, y: 150 });
    expect(world.player.speed).toBe(Rules.PLAYER_SPEED);
    expect(world.trees[0]).toMatchObject({ id: 'tree-a', woodYield: 5, hitsToFell: Rules.HITS_TO_FELL_TREE });
    expect(world.trees[0].footprint.radius).toBe(Rules.TREE_TRUNK_RADIUS);
    expect(world.items[0]).toMatchObject({ id: 'axe', kind: 'axe' });
  });

  it('rejects items the domain does not know', () => {
    const broken: LevelDto = { ...level, items: [{ id: 'mystery', kind: 'laser', x: 0, y: 0 }] };

    expect(() => toWorld(broken)).toThrow(/mystery.*laser/);
  });
});

describe('LevelRepositoryImpl', () => {
  it('maps whatever its data source fetches', () => {
    const repository = new LevelRepositoryImpl({ fetch: () => level });

    expect(repository.load().trees.map((tree) => tree.id)).toEqual(['tree-a']);
  });

  it('hands out an independent world on every load', () => {
    const repository = new LevelRepositoryImpl({ fetch: () => level });
    const first = repository.load();
    first.player.inventory.addWood(5);

    expect(repository.load().player.inventory.wood).toBe(0);
  });
});

describe('ProceduralForestLevelDataSource', () => {
  it('generates the same forest every time, with the axe and trees clear of the spawn point', () => {
    const dataSource = new ProceduralForestLevelDataSource();
    const forest = dataSource.fetch();

    expect(dataSource.fetch()).toEqual(forest);
    expect(forest.items).toEqual([expect.objectContaining({ kind: 'axe' })]);
    expect(forest.trees.length).toBeGreaterThan(40);
    const { playerStart } = forest;
    for (const tree of forest.trees) {
      expect(Math.hypot(tree.x - playerStart.x, tree.y - playerStart.y)).toBeGreaterThanOrEqual(200);
      expect(tree.wood).toBeGreaterThanOrEqual(5);
      expect(tree.wood).toBeLessThanOrEqual(6);
    }
  });
});

describe('InMemoryGameSessionRepository', () => {
  it('fails clearly when no game has been started', () => {
    expect(() => new InMemoryGameSessionRepository().current()).toThrow(/StartGameUseCase/);
  });
});
