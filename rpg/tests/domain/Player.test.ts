import { describe, expect, it } from 'vitest';
import { Player } from '../../src/domain/entities/Player';
import { Position } from '../../src/domain/value-objects/Position';
import { createPlayer } from '../fixtures';

describe('Player', () => {
  it('starts idle, with no next position', () => {
    const player = createPlayer(0, 0);
    expect(player.activity.kind).toBe('idle');
    expect(player.nextPosition(1000)).toBeNull();
  });

  it('computes next position as speed * seconds towards destination without moving', () => {
    const player = createPlayer(0, 0);
    player.walkTo(new Position(1000, 0));

    expect(player.nextPosition(500)).toEqual(new Position(50, 0));
    expect(player.position).toEqual(new Position(0, 0));
  });

  it('stop returns to idle', () => {
    const player = createPlayer(0, 0);
    player.walkTo(new Position(10, 0));
    player.stop();

    expect(player.isMoving).toBe(false);
    expect(player.activity.kind).toBe('idle');
  });

  it('tracks time spent on the current task', () => {
    const player = createPlayer();
    player.startChopping('tree-1');
    player.continueWork(300);

    expect(player.activity).toEqual({ kind: 'chopping', treeId: 'tree-1', elapsedMs: 300 });
  });

  it('rejects non-positive speed or radius', () => {
    expect(() => new Player(new Position(0, 0), 0, 10)).toThrow();
    expect(() => new Player(new Position(0, 0), 100, 0)).toThrow();
  });
});
