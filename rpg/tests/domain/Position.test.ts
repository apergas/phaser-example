import { describe, expect, it } from 'vitest';
import { Position } from '../../src/domain/value-objects/Position';

describe('Position', () => {
  it('computes euclidean distance', () => {
    expect(new Position(0, 0).distanceTo(new Position(3, 4))).toBe(5);
  });

  it('moves towards target by the given step', () => {
    const moved = new Position(0, 0).moveTowards(new Position(10, 0), 4);
    expect(moved).toEqual(new Position(4, 0));
  });

  it('snaps to target instead of overshooting', () => {
    const target = new Position(10, 0);
    expect(new Position(8, 0).moveTowards(target, 5)).toBe(target);
  });

  it('finds the point at a given distance in the direction of another', () => {
    expect(new Position(0, 0).pointAtDistance(5, new Position(30, 40))).toEqual(new Position(3, 4));
  });

  it('places the point below when both positions coincide', () => {
    expect(new Position(1, 1).pointAtDistance(5, new Position(1, 1))).toEqual(new Position(1, 6));
  });
});
