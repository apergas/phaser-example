import { describe, expect, it } from 'vitest';
import { Obstacle } from '../../src/domain/entities/Obstacle';
import { Player } from '../../src/domain/entities/Player';
import { World } from '../../src/domain/entities/World';
import { Position } from '../../src/domain/value-objects/Position';

describe('World', () => {
  it('moves the player when the path is clear', () => {
    const world = new World(1000, 1000, new Player(new Position(0, 0), 100, 10), []);
    world.player.moveTo(new Position(100, 0));

    world.advance(500);

    expect(world.player.position).toEqual(new Position(50, 0));
  });

  it('stops the player before walking into an obstacle', () => {
    const obstacle = new Obstacle(new Position(30, 0), 10);
    const world = new World(1000, 1000, new Player(new Position(0, 0), 100, 10), [obstacle]);
    world.player.moveTo(new Position(100, 0));

    world.advance(150); // would land at x=15, overlapping the obstacle footprint

    expect(world.player.position).toEqual(new Position(0, 0));
    expect(world.player.isMoving).toBe(false);
  });

  it('clamps the destination so the player footprint stays inside the world', () => {
    const world = new World(200, 100, new Player(new Position(50, 50), 1000, 10), []);

    world.movePlayerTo(new Position(-50, 500));
    world.advance(1000);

    expect(world.player.position).toEqual(new Position(10, 90));
  });
});
