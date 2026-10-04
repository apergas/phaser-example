import { describe, expect, it } from 'vitest';
import { Blueprints } from '../../src/domain/entities/Blueprint';
import { QuestLog } from '../../src/domain/quests/QuestLog';
import { Position } from '../../src/domain/value-objects/Position';
import { advanceFor, createPlayer, createWorld } from '../fixtures';

describe('QuestLog', () => {
  it('starts with every quest pending and no progress', () => {
    const world = createWorld();

    expect(new QuestLog().status(world)).toEqual([
      { id: 'pick-up-axe', progress: 0, target: 1, completed: false },
      { id: 'gather-wood', progress: 0, target: 15, completed: false },
      { id: 'build-house', progress: 0, target: 1, completed: false },
    ]);
  });

  it('completes a quest once and reports it a single time', () => {
    const world = createWorld();
    const questLog = new QuestLog();
    world.player.inventory.addTool('axe');

    expect(questLog.update(world)).toEqual([{ type: 'quest-completed', questId: 'pick-up-axe' }]);
    expect(questLog.update(world)).toEqual([]);
  });

  it('keeps the wood quest completed after the wood is spent', () => {
    const world = createWorld();
    const questLog = new QuestLog();
    world.player.inventory.addWood(16);
    questLog.update(world);

    world.player.inventory.spendWood(16);

    const woodQuest = questLog.status(world).find((quest) => quest.id === 'gather-wood');
    expect(woodQuest).toEqual({ id: 'gather-wood', progress: 15, target: 15, completed: true });
  });

  it('caps progress at the target', () => {
    const world = createWorld();
    world.player.inventory.addWood(40);

    expect(new QuestLog().status(world)[1].progress).toBe(15);
  });

  it('only counts finished houses', () => {
    const world = createWorld({ player: createPlayer(100, 100) });
    const questLog = new QuestLog();
    world.player.inventory.addWood(Blueprints.house.woodCost);
    questLog.update(world);
    world.orderConstruction(Blueprints.house, new Position(300, 100));

    expect(questLog.update(world)).toEqual([]); // site placed, not built yet
    advanceFor(world, 10000);
    expect(questLog.update(world)).toEqual([{ type: 'quest-completed', questId: 'build-house' }]);
  });
});
