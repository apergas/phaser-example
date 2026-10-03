import * as Phaser from 'phaser';
import { AdvanceWorldUseCase } from './application/use-cases/AdvanceWorldUseCase';
import { MovePlayerToUseCase } from './application/use-cases/MovePlayerToUseCase';
import { Obstacle } from './domain/entities/Obstacle';
import { Player } from './domain/entities/Player';
import { World } from './domain/entities/World';
import { Position } from './domain/value-objects/Position';
import { forestLevel } from './infrastructure/levels/forestLevel';
import { ForestScene } from './presentation/phaser/scenes/ForestScene';
import { PreloadScene } from './presentation/phaser/scenes/PreloadScene';

// Composition root: the only place that knows every layer and wires them together.
// World units are native art pixels (LPC: 32px tiles); the camera zooms them in.
const PLAYER_SPEED = 110;
const PLAYER_RADIUS = 8;
const TREE_TRUNK_RADIUS = 12;

const playerStart = new Position(forestLevel.playerStart.x, forestLevel.playerStart.y);
const treePositions = forestLevel.trees.map(({ x, y }) => new Position(x, y));

const world = new World(
  forestLevel.width,
  forestLevel.height,
  new Player(playerStart, PLAYER_SPEED, PLAYER_RADIUS),
  treePositions.map((position) => new Obstacle(position, TREE_TRUNK_RADIUS)),
);

const forestScene = new ForestScene({
  width: forestLevel.width,
  height: forestLevel.height,
  initialPlayerPosition: playerStart,
  treePositions,
  movePlayerTo: new MovePlayerToUseCase(world),
  advanceWorld: new AdvanceWorldUseCase(world),
});

new Phaser.Game({
  type: Phaser.AUTO,
  backgroundColor: '#0e150e',
  pixelArt: true,
  scale: {
    mode: Phaser.Scale.RESIZE,
    parent: 'app',
    width: '100%',
    height: '100%',
  },
  scene: [new PreloadScene(ForestScene.KEY), forestScene],
});
