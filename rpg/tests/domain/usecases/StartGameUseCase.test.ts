import { describe, expect, it } from 'vitest';
import { GameSessionRepositoryImpl } from '../../../src/data/repositories/GameSessionRepositoryImpl';
import type { LevelRepository } from '../../../src/domain/repositories/LevelRepository';
import { GetGameStateUseCase } from '../../../src/domain/usecases/GetGameStateUseCase';
import { StartGameUseCase } from '../../../src/domain/usecases/StartGameUseCase';
import { createAxe, createPlayer, createTree, createWorld } from '../../fixtures';

/** A fake repository handing out a fresh small world on every load, like a real level would. */
const smallLevel: LevelRepository = {
  load: () =>
    createWorld({ player: createPlayer(200, 150), trees: [createTree('tree-a', 50, 60)], items: [createAxe(220, 150)] }),
};

describe('StartGameUseCase', () => {
  it('starts a session in the level world with a fresh quest log', () => {
    const sessions = new GameSessionRepositoryImpl();

    new StartGameUseCase(smallLevel, sessions).execute();

    const state = new GetGameStateUseCase(sessions);
    expect(state.snapshot().trees).toEqual([{ id: 'tree-a', position: { x: 50, y: 60 } }]);
    expect(state.player()).toMatchObject({ position: { x: 200, y: 150 }, wood: 0, hasAxe: false, activity: 'idle' });
    expect(state.quests().every((quest) => !quest.completed)).toBe(true);
  });

  it('replaces the previous game when started again', () => {
    const sessions = new GameSessionRepositoryImpl();
    const start = new StartGameUseCase(smallLevel, sessions);
    start.execute();
    sessions.current().world.player.inventory.addWood(10);

    start.execute();

    expect(sessions.current().world.player.inventory.wood).toBe(0);
  });
});
