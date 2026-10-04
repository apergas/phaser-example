import * as Phaser from 'phaser';
import { AdvanceWorldUseCase } from './application/use-cases/AdvanceWorldUseCase';
import { ChopTreeUseCase } from './application/use-cases/ChopTreeUseCase';
import { ConstructBuildingUseCase } from './application/use-cases/ConstructBuildingUseCase';
import { GetGameStateUseCase } from './application/use-cases/GetGameStateUseCase';
import { MovePlayerToUseCase } from './application/use-cases/MovePlayerToUseCase';
import { StartGameUseCase } from './application/use-cases/StartGameUseCase';
import { ProceduralForestLevel } from './infrastructure/levels/ProceduralForestLevel';
import { InMemoryGameSessionRepository } from './infrastructure/persistence/InMemoryGameSessionRepository';
import { Hud } from './presentation/dom/Hud';
import { ForestScene } from './presentation/phaser/scenes/ForestScene';
import { PreloadScene } from './presentation/phaser/scenes/PreloadScene';
import { GameViewModel } from './presentation/viewmodels/GameViewModel';

// Composition root: the only place that knows every layer and wires them together.

const sessions = new InMemoryGameSessionRepository();
new StartGameUseCase(new ProceduralForestLevel(), sessions).execute();
const gameState = new GetGameStateUseCase(sessions);

const viewModel = new GameViewModel({
  movePlayerTo: new MovePlayerToUseCase(sessions),
  chopTree: new ChopTreeUseCase(sessions),
  constructBuilding: new ConstructBuildingUseCase(sessions),
  advanceWorld: new AdvanceWorldUseCase(sessions),
  gameState,
});

const app = document.querySelector<HTMLElement>('#app');
if (!app) throw new Error('Missing #app container');

const hud = new Hud(app, { build: (blueprint) => viewModel.requestBuild(blueprint) });
const forestScene = new ForestScene({ viewModel, hud });

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
  Object.assign(window, { __rpg: { game, gameState, viewModel } });
}
