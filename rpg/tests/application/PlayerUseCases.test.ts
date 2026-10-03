import { describe, expect, it } from 'vitest';
import { AdvanceWorldUseCase } from '../../src/application/use-cases/AdvanceWorldUseCase';
import { MovePlayerToUseCase } from '../../src/application/use-cases/MovePlayerToUseCase';
import { Player } from '../../src/domain/entities/Player';
import { World } from '../../src/domain/entities/World';
import { Position } from '../../src/domain/value-objects/Position';

describe('Player use cases', () => {
  it('move + advance drives the player to the clicked point', () => {
    const world = new World(1000, 1000, new Player(new Position(50, 50), 200, 10), []);
    const movePlayerTo = new MovePlayerToUseCase(world);
    const advanceWorld = new AdvanceWorldUseCase(world);

    movePlayerTo.execute(50, 150);
    const position = advanceWorld.execute(1000);

    expect(position).toEqual(new Position(50, 150));
  });
});
