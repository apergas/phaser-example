import { describe, expect, it } from 'vitest';
import { Player } from '../../src/domain/entities/Player';
import { Position } from '../../src/domain/value-objects/Position';

const createPlayer = () => new Player(new Position(0, 0), 100, 10);

describe('Player', () => {
  it('has no next position without a destination', () => {
    expect(createPlayer().nextPosition(1000)).toBeNull();
  });

  it('computes next position as speed * seconds towards destination without moving', () => {
    const player = createPlayer();
    player.moveTo(new Position(1000, 0));

    expect(player.nextPosition(500)).toEqual(new Position(50, 0));
    expect(player.position).toEqual(new Position(0, 0));
  });

  it('stops moving once placed at destination', () => {
    const player = createPlayer();
    player.moveTo(new Position(10, 0));
    player.placeAt(new Position(10, 0));

    expect(player.isMoving).toBe(false);
  });

  it('stop clears destination', () => {
    const player = createPlayer();
    player.moveTo(new Position(10, 0));
    player.stop();

    expect(player.isMoving).toBe(false);
  });

  it('rejects non-positive speed or radius', () => {
    expect(() => new Player(new Position(0, 0), 0, 10)).toThrow();
    expect(() => new Player(new Position(0, 0), 100, 0)).toThrow();
  });
});
