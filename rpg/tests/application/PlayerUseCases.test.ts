import { describe, expect, it } from 'vitest';
import { AdvanceWorldUseCase } from '../../src/application/use-cases/AdvanceWorldUseCase';
import { ChopTreeUseCase } from '../../src/application/use-cases/ChopTreeUseCase';
import { ConstructBuildingUseCase } from '../../src/application/use-cases/ConstructBuildingUseCase';
import { GetGameStateUseCase } from '../../src/application/use-cases/GetGameStateUseCase';
import { MovePlayerToUseCase } from '../../src/application/use-cases/MovePlayerToUseCase';
import { Blueprints } from '../../src/domain/entities/Blueprint';
import { QuestLog } from '../../src/domain/quests/QuestLog';
import { Rules } from '../../src/domain/rules';
import { advanceFor, createAxe, createPlayer, createTree, createWorld } from '../fixtures';

describe('Use cases', () => {
  it('move + advance drives the player to the clicked point', () => {
    const world = createWorld({ player: createPlayer(50, 50) });
    new MovePlayerToUseCase(world).execute(50, 150);

    new AdvanceWorldUseCase(world, new QuestLog()).execute(1000);

    expect(new GetGameStateUseCase(world, new QuestLog()).player().position).toEqual({ x: 50, y: 150 });
  });

  it('gather and build loop: pick up axe, chop trees, build a house', () => {
    const world = createWorld({
      player: createPlayer(100, 100),
      items: [createAxe(120, 100)],
      trees: [createTree('tree-1', 200, 100), createTree('tree-2', 200, 200), createTree('tree-3', 100, 200)],
    });
    const state = new GetGameStateUseCase(world, new QuestLog());
    const chop = new ChopTreeUseCase(world);
    const construct = new ConstructBuildingUseCase(world);
    const chopTime = 2000 + Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE;

    expect(chop.execute('tree-1')).toBe('no-axe');
    new MovePlayerToUseCase(world).execute(125, 100);
    advanceFor(world, 500);
    expect(state.player().hasAxe).toBe(true);

    for (const treeId of ['tree-1', 'tree-2', 'tree-3']) {
      expect(chop.execute(treeId)).toBe('ok');
      advanceFor(world, chopTime);
    }
    expect(state.player().wood).toBe(18);
    expect(state.buildOptions()).toEqual([
      { blueprintId: 'house', woodCost: Blueprints.house.woodCost, affordable: true },
    ]);

    const result = construct.execute('house', 400, 400);
    expect(result.ok).toBe(true);
    advanceFor(world, 6000 + Rules.HAMMER_INTERVAL_MS * Blueprints.house.hitsToBuild);

    expect(state.snapshot().buildings).toEqual([
      { id: 'building-1', blueprintId: 'house', position: { x: 400, y: 400 }, progress: 1 },
    ]);
    expect(state.player().wood).toBe(18 - Blueprints.house.woodCost);
  });

  it('reports quest progress and completions as the loop advances', () => {
    const world = createWorld({ player: createPlayer(100, 100), items: [createAxe(110, 100)] });
    const questLog = new QuestLog();
    const advance = new AdvanceWorldUseCase(world, questLog);
    const state = new GetGameStateUseCase(world, questLog);

    expect(state.quests().map((quest) => [quest.id, quest.current])).toEqual([
      ['pick-up-axe', true],
      ['gather-wood', false],
      ['build-house', false],
    ]);

    new MovePlayerToUseCase(world).execute(110, 100);
    const events = advance.execute(200);
    world.player.inventory.addWood(7);

    expect(events).toContainEqual({ type: 'quest-completed', questId: 'pick-up-axe' });
    expect(state.quests()[1]).toEqual({ id: 'gather-wood', progress: 7, target: 15, completed: false, current: true });
  });

  it('reports the swing progress while working', () => {
    const world = createWorld({ player: createPlayer(100, 100), trees: [createTree('tree-1', 120, 100)] });
    world.player.inventory.addTool('axe');
    new ChopTreeUseCase(world).execute('tree-1');

    world.advance(Rules.CHOP_INTERVAL_MS / 2);

    const player = new GetGameStateUseCase(world, new QuestLog()).player();
    expect(player.activity).toBe('chopping');
    expect(player.swingProgress).toBeCloseTo(0.5);
    expect(player.target).toEqual({ x: 120, y: 100 });
  });
});
