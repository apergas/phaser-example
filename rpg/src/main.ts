import * as Phaser from 'phaser';
import { AdvanceWorldUseCase } from './application/use-cases/AdvanceWorldUseCase';
import { ChopTreeUseCase } from './application/use-cases/ChopTreeUseCase';
import { ConstructBuildingUseCase } from './application/use-cases/ConstructBuildingUseCase';
import { GetGameStateUseCase } from './application/use-cases/GetGameStateUseCase';
import { MovePlayerToUseCase } from './application/use-cases/MovePlayerToUseCase';
import { GroundItem } from './domain/entities/GroundItem';
import { Player } from './domain/entities/Player';
import { Tree } from './domain/entities/Tree';
import { World } from './domain/entities/World';
import { QuestLog } from './domain/quests/QuestLog';
import { Rules } from './domain/rules';
import { Position } from './domain/value-objects/Position';
import { forestLevel } from './infrastructure/levels/forestLevel';
import { Hud } from './presentation/dom/Hud';
import { ForestScene } from './presentation/phaser/scenes/ForestScene';
import { PreloadScene } from './presentation/phaser/scenes/PreloadScene';

// Composition root: the only place that knows every layer and wires them together.
// World units are native art pixels (LPC: 32px tiles); the camera zooms them in.
const PLAYER_SPEED = 110;
const PLAYER_RADIUS = 8;
const TREE_TRUNK_RADIUS = 12;

const world = new World(
  forestLevel.width,
  forestLevel.height,
  new Player(new Position(forestLevel.playerStart.x, forestLevel.playerStart.y), PLAYER_SPEED, PLAYER_RADIUS),
  forestLevel.trees.map(
    (tree) => new Tree(tree.id, new Position(tree.x, tree.y), TREE_TRUNK_RADIUS, tree.wood, Rules.HITS_TO_FELL_TREE),
  ),
  [new GroundItem('axe', 'axe', new Position(forestLevel.axe.x, forestLevel.axe.y))],
);

const questLog = new QuestLog();
const gameState = new GetGameStateUseCase(world, questLog);

const app = document.querySelector<HTMLElement>('#app');
if (!app) throw new Error('Missing #app container');

// The HUD and the scene reference each other: the HUD asks the scene to start placing a building.
let forestScene: ForestScene | undefined = undefined;
const hud = new Hud(app, (blueprintId) => forestScene?.startPlacing(blueprintId));

forestScene = new ForestScene({
  movePlayerTo: new MovePlayerToUseCase(world),
  chopTree: new ChopTreeUseCase(world),
  constructBuilding: new ConstructBuildingUseCase(world),
  advanceWorld: new AdvanceWorldUseCase(world, questLog),
  gameState,
  hud,
});

const game = new Phaser.Game({
  type: Phaser.AUTO,
  backgroundColor: '#0e150e',
  pixelArt: true,
  scale: {
    mode: Phaser.Scale.RESIZE,
    parent: app,
    width: '100%',
    height: '100%',
  },
  scene: [new PreloadScene(ForestScene.KEY), forestScene],
});

// Dev-only handle for browser automation (e2e checks); stripped from production builds.
if (import.meta.env.DEV) {
  Object.assign(window, { __rpg: { game, gameState } });
}
