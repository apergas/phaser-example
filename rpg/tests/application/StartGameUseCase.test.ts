import { describe, expect, it } from 'vitest';
import type { LevelDefinition, LevelSource } from '../../src/application/ports/LevelSource';
import { GetGameStateUseCase } from '../../src/application/use-cases/GetGameStateUseCase';
import { StartGameUseCase } from '../../src/application/use-cases/StartGameUseCase';
import { Rules } from '../../src/domain/rules';
import { InMemoryGameSessionRepository } from '../../src/infrastructure/persistence/InMemoryGameSessionRepository';

const level: LevelDefinition = {
  width: 400,
  height: 300,
  playerStart: { x: 200, y: 150 },
  trees: [{ id: 'tree-a', x: 50, y: 60, wood: 5 }],
  items: [{ id: 'axe', kind: 'axe', x: 220, y: 150 }],
};
const fixedLevel: LevelSource = { load: () => level };

describe('StartGameUseCase', () => {
  it('builds the world and a fresh quest log from the level', () => {
    const sessions = new InMemoryGameSessionRepository();

    new StartGameUseCase(fixedLevel, sessions).execute();

    const state = new GetGameStateUseCase(sessions);
    expect(state.snapshot()).toEqual({
      width: 400,
      height: 300,
      trees: [{ id: 'tree-a', position: { x: 50, y: 60 } }],
      items: [{ id: 'axe', kind: 'axe', position: { x: 220, y: 150 } }],
      buildings: [],
    });
    expect(state.player()).toMatchObject({ position: { x: 200, y: 150 }, wood: 0, hasAxe: false, activity: 'idle' });
    expect(state.quests().every((quest) => !quest.completed)).toBe(true);
    expect(sessions.current().world.trees[0].footprint.radius).toBe(Rules.TREE_TRUNK_RADIUS);
  });

  it('replaces the previous game when started again', () => {
    const sessions = new InMemoryGameSessionRepository();
    const start = new StartGameUseCase(fixedLevel, sessions);
    start.execute();
    sessions.current().world.player.inventory.addWood(10);

    start.execute();

    expect(sessions.current().world.player.inventory.wood).toBe(0);
  });
});

describe('InMemoryGameSessionRepository', () => {
  it('fails clearly when no game has been started', () => {
    expect(() => new InMemoryGameSessionRepository().current()).toThrow(/StartGameUseCase/);
  });
});
