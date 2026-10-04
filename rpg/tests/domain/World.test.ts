import { describe, expect, it } from 'vitest';
import { Blueprints } from '../../src/domain/entities/Blueprint';
import { World } from '../../src/domain/world/World';
import { Rules } from '../../src/domain/rules';
import { Position } from '../../src/domain/value-objects/Position';
import { WOOD_PER_TREE, advanceFor, createAxe, createPlayer, createTree, createWorld } from '../fixtures';

const house = Blueprints.house;

describe('World movement', () => {
  it('moves the player when the path is clear', () => {
    const world = createWorld({ player: createPlayer(100, 100) });
    world.movePlayerTo(new Position(200, 100));

    world.advance(500);

    expect(world.player.position).toEqual(new Position(150, 100));
  });

  it('stops the player before walking into a tree', () => {
    const world = createWorld({ player: createPlayer(100, 100), trees: [createTree('tree-1', 130, 100)] });
    world.movePlayerTo(new Position(200, 100));

    world.advance(150); // would land at x=115, overlapping the trunk

    expect(world.player.position).toEqual(new Position(100, 100));
    expect(world.player.isMoving).toBe(false);
  });

  it('clamps the destination so the player footprint stays inside the world', () => {
    const world = new World(200, 100, createPlayer(50, 50), []);

    world.movePlayerTo(new Position(-50, 500));
    advanceFor(world, 2000);

    expect(world.player.position).toEqual(new Position(8, 92));
  });
});

describe('World items', () => {
  it('picks up a tool when the player walks over it', () => {
    const world = createWorld({ player: createPlayer(100, 100), items: [createAxe(150, 100)] });
    world.movePlayerTo(new Position(160, 100));

    const events = advanceFor(world, 1000);

    expect(events).toContainEqual({ type: 'item-picked-up', itemId: 'axe-1', kind: 'axe' });
    expect(world.player.inventory.hasTool('axe')).toBe(true);
    expect(world.items).toHaveLength(0);
  });
});

describe('World chopping', () => {
  const worldWithAxeAndTree = () => {
    const world = createWorld({ player: createPlayer(100, 100), trees: [createTree('tree-1', 200, 100)] });
    world.player.inventory.addTool('axe');
    return world;
  };

  it('refuses to chop without an axe', () => {
    const world = createWorld({ trees: [createTree('tree-1', 200, 100)] });

    expect(world.orderChop('tree-1')).toBe('no-axe');
    expect(world.player.isMoving).toBe(false);
  });

  it('reports unknown trees', () => {
    expect(worldWithAxeAndTree().orderChop('nope')).toBe('unknown-tree');
  });

  it('walks up to the side of the tree facing the player and starts chopping', () => {
    const world = worldWithAxeAndTree();

    expect(world.orderChop('tree-1')).toBe('ok');
    advanceFor(world, 1500);

    expect(world.player.activity).toMatchObject({ kind: 'working', intent: { kind: 'chop' } });
    // trunk (10) + player (8) + gap (2) to the left, a pixel in front so it is drawn over the trunk
    expect(world.player.position).toEqual(new Position(180, 101));
  });

  it('chops from the other side when the near side is blocked', () => {
    const world = createWorld({
      player: createPlayer(100, 300),
      trees: [createTree('tree-1', 200, 100), createTree('neighbour', 165, 100)],
    });
    world.player.inventory.addTool('axe');
    world.orderChop('tree-1');

    advanceFor(world, 4000);

    expect(world.player.activity).toMatchObject({ kind: 'working', intent: { kind: 'chop' } });
    expect(world.player.position.x).toBeGreaterThan(200);
  });

  it('hits the tree once per interval and fells it, adding its wood', () => {
    const world = worldWithAxeAndTree();
    world.orderChop('tree-1');
    advanceFor(world, 1500); // arrive

    const events = advanceFor(world, Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE + 100);

    expect(events.filter((event) => event.type === 'tree-hit')).toHaveLength(Rules.HITS_TO_FELL_TREE);
    expect(events).toContainEqual({ type: 'tree-felled', treeId: 'tree-1', wood: WOOD_PER_TREE });
    expect(world.player.inventory.wood).toBe(WOOD_PER_TREE);
    expect(world.trees).toHaveLength(0);
    expect(world.player.activity.kind).toBe('idle');
  });

  it('reports when another tree stands in the way of the one to chop', () => {
    const world = createWorld({
      player: createPlayer(100, 100),
      trees: [createTree('tree-1', 300, 100), createTree('in-the-way', 180, 100)],
    });
    world.player.inventory.addTool('axe');
    world.orderChop('tree-1');

    const events = advanceFor(world, 3000);

    expect(events).toContainEqual({ type: 'player-blocked' });
    expect(world.player.activity.kind).toBe('idle');
  });

  it('frees the path once the tree is felled', () => {
    const world = worldWithAxeAndTree();
    world.orderChop('tree-1');
    advanceFor(world, 1500 + Rules.CHOP_INTERVAL_MS * Rules.HITS_TO_FELL_TREE + 100);

    world.movePlayerTo(new Position(300, 100));
    advanceFor(world, 3000);

    expect(world.player.position).toEqual(new Position(300, 100));
  });
});

describe('World construction', () => {
  const richWorld = () => {
    const world = createWorld({ player: createPlayer(100, 100) });
    world.player.inventory.addWood(house.woodCost + 2);
    return world;
  };

  it('refuses to build without enough wood', () => {
    const world = createWorld();

    expect(world.orderConstruction(house, new Position(400, 400))).toEqual({ ok: false, reason: 'not-enough-wood' });
    expect(world.buildings).toHaveLength(0);
  });

  it('refuses sites that overlap a tree, the player or the world edge, without charging', () => {
    const world = createWorld({ player: createPlayer(100, 100), trees: [createTree('tree-1', 400, 400)] });
    world.player.inventory.addWood(house.woodCost);

    expect(world.orderConstruction(house, new Position(420, 400))).toEqual({ ok: false, reason: 'blocked' });
    expect(world.orderConstruction(house, new Position(110, 100))).toEqual({ ok: false, reason: 'blocked' });
    expect(world.orderConstruction(house, new Position(10, 500))).toEqual({ ok: false, reason: 'blocked' });
    expect(world.player.inventory.wood).toBe(house.woodCost);
  });

  it('charges the wood, places the site and walks the player to it', () => {
    const world = richWorld();

    const result = world.orderConstruction(house, new Position(300, 100));

    expect(result.ok).toBe(true);
    expect(world.player.inventory.wood).toBe(2);
    expect(world.buildings).toHaveLength(1);
    expect(world.player.isMoving).toBe(true);
  });

  it('builds from the front of the site', () => {
    const world = richWorld();
    world.orderConstruction(house, new Position(300, 100));

    advanceFor(world, 3000);

    expect(world.player.activity).toMatchObject({ kind: 'working', intent: { kind: 'construct' } });
    expect(world.player.position).toEqual(new Position(300, 100 + house.footprintRadius + 10));
  });

  it('hammers until the building is complete', () => {
    const world = richWorld();
    world.orderConstruction(house, new Position(300, 100));

    const events = advanceFor(world, 3000 + Rules.HAMMER_INTERVAL_MS * house.hitsToBuild);

    expect(events.filter((event) => event.type === 'building-hammered')).toHaveLength(house.hitsToBuild);
    expect(events).toContainEqual({ type: 'building-completed', buildingId: 'building-1' });
    expect(world.buildings[0].isComplete).toBe(true);
    expect(world.player.activity.kind).toBe('idle');
  });

  it('blocks movement through the building', () => {
    const world = richWorld();
    world.orderConstruction(house, new Position(300, 100));
    advanceFor(world, 3000 + Rules.HAMMER_INTERVAL_MS * house.hitsToBuild);

    for (const waypoint of [new Position(200, 200), new Position(200, 100)]) {
      world.movePlayerTo(waypoint);
      advanceFor(world, 3000);
    }
    world.movePlayerTo(new Position(500, 100));
    advanceFor(world, 5000);

    expect(world.player.position.x).toBeLessThan(300 - house.footprintRadius);
  });
});
