import { describe, expect, it } from 'vitest';
import { AdvanceWorldUseCase } from '../../../src/domain/usecases/AdvanceWorldUseCase';
import { ChopTreeUseCase } from '../../../src/domain/usecases/ChopTreeUseCase';
import { ConstructBuildingUseCase } from '../../../src/domain/usecases/ConstructBuildingUseCase';
import { GetGameStateUseCase } from '../../../src/domain/usecases/GetGameStateUseCase';
import { MovePlayerToUseCase } from '../../../src/domain/usecases/MovePlayerToUseCase';
import { Blueprints } from '../../../src/domain/entities/Blueprint';
import { Rules } from '../../../src/domain/rules';
import { createAxe, createPlayer, createTree, createWorld, sessionFor } from '../../fixtures';

/** Runs the simulation through the use case, in 16ms steps, collecting every notice. */
function play(advance: AdvanceWorldUseCase, totalMs: number) {
  const events = [];
  for (let elapsed = 0; elapsed < totalMs; elapsed += 16) events.push(...advance.execute(16));
  return events;
}

describe('Use cases', () => {
  it('move + advance drives the player to the clicked point', () => {
    const sessions = sessionFor(createWorld({ player: createPlayer(50, 50) }));
    new MovePlayerToUseCase(sessions).execute(50, 150);

    new AdvanceWorldUseCase(sessions).execute(1000);

    expect(new GetGameStateUseCase(sessions).player().position).toEqual({ x: 50, y: 150 });
  });

  it('gather and build loop: pick up axe, chop trees, build a house', () => {
    const sessions = sessionFor(
      createWorld({
        player: createPlayer(100, 100),
        items: [createAxe(120, 100)],
        trees: [createTree('tree-1', 200, 100), createTree('tree-2', 200, 200), createTree('tree-3', 100, 200)],
      }),
    );
    const state = new GetGameStateUseCase(sessions);
    const advance = new AdvanceWorldUseCase(sessions);
    const chop = new ChopTreeUseCase(sessions);
    const chopTime = 2000 + Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE;

    expect(chop.execute('tree-1')).toBe('no-axe');
    new MovePlayerToUseCase(sessions).execute(125, 100);
    play(advance, 500);
    expect(state.player().hasAxe).toBe(true);

    for (const treeId of ['tree-1', 'tree-2', 'tree-3']) {
      expect(chop.execute(treeId)).toBe('ok');
      play(advance, chopTime);
    }
    expect(state.player().wood).toBe(18);
    expect(state.buildOptions()).toEqual([{ blueprintId: 'house', woodCost: Blueprints.house.woodCost, affordable: true }]);

    expect(new ConstructBuildingUseCase(sessions).execute('house', 400, 400).ok).toBe(true);
    const events = play(advance, 6000 + Rules.HAMMER_INTERVAL_MS * Blueprints.house.hitsToBuild);

    expect(events).toContainEqual({ type: 'building-completed', buildingId: 'building-1', blueprintId: 'house' });
    expect(events).toContainEqual({ type: 'quest-completed', questId: 'build-house' });
    expect(state.snapshot().buildings).toEqual([
      { id: 'building-1', blueprintId: 'house', position: { x: 400, y: 400 }, progress: 1 },
    ]);
    expect(state.player().wood).toBe(18 - Blueprints.house.woodCost);
  });

  it('reports quest progress and completions as the loop advances', () => {
    const world = createWorld({ player: createPlayer(100, 100), items: [createAxe(110, 100)] });
    const sessions = sessionFor(world);
    const state = new GetGameStateUseCase(sessions);

    expect(state.quests().map((quest) => [quest.id, quest.current])).toEqual([
      ['pick-up-axe', true],
      ['gather-wood', false],
      ['build-house', false],
    ]);

    new MovePlayerToUseCase(sessions).execute(110, 100);
    const events = new AdvanceWorldUseCase(sessions).execute(200);
    world.player.inventory.addWood(7);

    expect(events).toContainEqual({ type: 'quest-completed', questId: 'pick-up-axe' });
    expect(state.quests()[1]).toEqual({ id: 'gather-wood', progress: 7, target: 15, completed: false, current: true });
  });

  it('reports the work as chopping, with swing progress and target', () => {
    const world = createWorld({ player: createPlayer(100, 100), trees: [createTree('tree-1', 120, 100)] });
    world.player.inventory.addTool('axe');
    const sessions = sessionFor(world);
    new ChopTreeUseCase(sessions).execute('tree-1');

    world.advance(Rules.CHOP_INTERVAL_MS / 2);

    const player = new GetGameStateUseCase(sessions).player();
    expect(player.activity).toBe('chopping');
    expect(player.swingProgress).toBeCloseTo(0.5);
    expect(player.target).toEqual({ x: 120, y: 100 });
  });
});
