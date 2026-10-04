import { describe, expect, it } from 'vitest';
import { Blueprints } from '../../src/domain/entities/Blueprint';
import { Rules } from '../../src/domain/rules';
import { Labels } from '../../src/presentation/labels';
import { createAxe, createPlayer, createTree, createWorld } from '../fixtures';
import { tickFor, viewModelFor } from './viewModelFixture';

const house = Blueprints.house;

describe('GameViewModel', () => {
  it('greets the player and starts with the quest list', () => {
    const vm = viewModelFor(createWorld());

    expect(vm.hud.state.message?.text).toBe(Labels.messages.welcome);
    expect(vm.hud.state.questBadge).toBe('0/3');
    expect(vm.hud.state.quests[0]).toEqual({ title: 'Recoge el hacha', progressText: '', status: 'current' });
    expect(vm.hud.state.quests[1]).toEqual({ title: 'Consigue al menos 15 de madera', progressText: '0/15', status: 'pending' });
  });

  it('a click on empty ground walks there', () => {
    const vm = viewModelFor(createWorld({ player: createPlayer(100, 100) }));

    vm.mapClicked({ x: 150, y: 100 }, null);
    tickFor(vm, 1000);

    expect(vm.player.state.position).toEqual({ x: 150, y: 100 });
    expect(vm.player.state.facing).toBe('right');
  });

  it('a click on a tree without the axe explains why nothing happens', () => {
    const vm = viewModelFor(createWorld({ trees: [createTree('tree-1', 300, 100)] }));

    vm.mapClicked({ x: 300, y: 80 }, 'tree-1');

    expect(vm.hud.state.message?.text).toBe(Labels.messages.needAxe);
  });

  it('turns picking up the axe into an effect, a message and the axe pose', () => {
    const vm = viewModelFor(createWorld({ player: createPlayer(100, 100), items: [createAxe(110, 100)] }));

    vm.mapClicked({ x: 110, y: 100 }, null);
    const effects = tickFor(vm, 300);

    expect(effects).toContainEqual({ kind: 'item-picked-up', itemId: 'axe-1' });
    expect(vm.hud.state.hasAxe).toBe(true);
    expect(vm.player.state.pose).toEqual({ kind: 'idle', withAxe: true });
  });

  it('chopping faces the tree, swings, and reports hits and the fall', () => {
    const world = createWorld({ player: createPlayer(100, 100), trees: [createTree('tree-1', 200, 100)] });
    world.player.inventory.addTool('axe');
    const vm = viewModelFor(world);

    vm.mapClicked({ x: 200, y: 80 }, 'tree-1');
    const effects = tickFor(vm, 1500);
    expect(vm.player.state.facing).toBe('right');
    expect(vm.player.state.pose).toMatchObject({ kind: 'work', tool: 'axe' });

    effects.push(...tickFor(vm, Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE));
    expect(effects.filter((effect) => effect.kind === 'tree-hit')).toHaveLength(Rules.HITS_TO_FELL_TREE);
    expect(effects).toContainEqual({ kind: 'tree-felled', treeId: 'tree-1', fromX: 180 });
    expect(vm.hud.state.wood).toBe(6);
  });

  it('the build menu shows what is missing until the house is affordable', () => {
    const world = createWorld();
    const vm = viewModelFor(world);
    world.player.inventory.addWood(10);
    vm.tick(16);

    expect(vm.hud.state.buildItems).toEqual([
      { blueprint: 'house', name: 'Casa', costText: '15 de madera', missingText: 'Faltan 5', enabled: false },
    ]);

    vm.requestBuild('house');
    expect(vm.placement).toBeNull();
    expect(vm.hud.state.message?.text).toBe(Labels.messages.notEnoughWood);
  });

  it('placement previews validity, ignores blocked sites and places on a free one', () => {
    const world = createWorld({ player: createPlayer(100, 100), trees: [createTree('tree-1', 400, 400)] });
    world.player.inventory.addWood(house.woodCost);
    const vm = viewModelFor(world);
    vm.tick(16);

    vm.requestBuild('house');
    expect(vm.hud.state.buildLocked).toBe(true);

    vm.pointerMoved({ x: 410, y: 400 });
    expect(vm.placement).toEqual({ blueprint: 'house', position: { x: 410, y: 400 }, valid: false });
    expect(vm.mapClicked({ x: 410, y: 400 }, null)).toEqual([]);
    expect(vm.hud.state.message?.text).toBe(Labels.messages.blocked);
    expect(vm.placement).not.toBeNull();

    const effects = vm.mapClicked({ x: 250, y: 250 }, null);
    expect(effects).toEqual([
      { kind: 'building-placed', building: { id: 'building-1', blueprintId: 'house', position: { x: 250, y: 250 }, progress: 0 } },
    ]);
    expect(vm.placement).toBeNull();
  });

  it('a secondary click or cancel leaves placement mode without building', () => {
    const world = createWorld();
    world.player.inventory.addWood(house.woodCost);
    const vm = viewModelFor(world);
    vm.tick(16);

    vm.requestBuild('house');
    vm.mapClicked({ x: 500, y: 500 }, null, 'secondary');

    expect(vm.placement).toBeNull();
    expect(world.buildings).toHaveLength(0);
    expect(vm.hud.state.buildLocked).toBe(false);
  });

  it('announces completed quests, and the last one with a final message', () => {
    const world = createWorld({ player: createPlayer(100, 100) });
    world.player.inventory.addTool('axe');
    world.player.inventory.addWood(house.woodCost);
    const vm = viewModelFor(world);
    vm.tick(16);
    expect(vm.hud.state.questBadge).toBe('2/3');

    vm.requestBuild('house');
    vm.mapClicked({ x: 300, y: 100 }, null);
    const effects = tickFor(vm, 6000 + Rules.HAMMER_INTERVAL_MS * house.hitsToBuild);

    expect(effects).toContainEqual({ kind: 'building-completed', buildingId: 'building-1' });
    expect(vm.hud.state.questBadge).toBe('3/3');
    expect(vm.hud.state.message?.text).toBe(Labels.messages.allQuestsCompleted);
  });

  it('gives every message a new serial so repeated texts are shown again', () => {
    const vm = viewModelFor(createWorld({ trees: [createTree('tree-1', 300, 100)] }));

    vm.mapClicked({ x: 300, y: 80 }, 'tree-1');
    const first = vm.hud.state.message?.serial;
    vm.mapClicked({ x: 300, y: 80 }, 'tree-1');

    expect(vm.hud.state.message?.serial).toBe((first ?? 0) + 1);
  });
});
