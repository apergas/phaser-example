import { describe, expect, it } from 'vitest';
import { Blueprints } from '../../src/domain/entities/Blueprint';
import { Building } from '../../src/domain/entities/Building';
import { Position } from '../../src/domain/value-objects/Position';
import { createTree } from '../fixtures';

describe('Tree', () => {
  it('is felled after its required hits and ignores further hits', () => {
    const tree = createTree('tree-1', 0, 0);
    for (let i = 0; i < tree.hitsToFell; i++) tree.hit();

    expect(tree.isFelled).toBe(true);
    tree.hit();
    expect(tree.hitsRemaining).toBe(0);
  });
});

describe('Building', () => {
  it('progresses with each hammer hit until complete', () => {
    const building = new Building('building-1', Blueprints.house, new Position(0, 0));
    building.hammer();

    expect(building.progress).toBeCloseTo(1 / Blueprints.house.hitsToBuild);
    for (let i = 1; i < Blueprints.house.hitsToBuild; i++) building.hammer();
    expect(building.isComplete).toBe(true);
  });
});
