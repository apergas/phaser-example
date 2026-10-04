import * as Phaser from 'phaser';
import { AdvanceWorldUseCase } from './domain/usecases/AdvanceWorldUseCase';
import { ChopTreeUseCase } from './domain/usecases/ChopTreeUseCase';
import { ConstructBuildingUseCase } from './domain/usecases/ConstructBuildingUseCase';
import { GetGameStateUseCase } from './domain/usecases/GetGameStateUseCase';
import { MovePlayerToUseCase } from './domain/usecases/MovePlayerToUseCase';
import { StartGameUseCase } from './domain/usecases/StartGameUseCase';
import { ProceduralForestLevelDataSource } from './data/datasources/ProceduralForestLevelDataSource';
import { LevelRepositoryImpl } from './data/repositories/LevelRepositoryImpl';
import { GameSessionRepositoryImpl } from './data/repositories/GameSessionRepositoryImpl';
import { Hud } from './presentation/screens/forest/hud/Hud';
import { ForestScene } from './presentation/screens/forest/ForestScene';
import { PreloadScene } from './presentation/screens/preload/PreloadScene';
import { ForestViewModel } from './presentation/screens/forest/ForestViewModel';

// Composition root: the only place that knows every layer and wires them together.

const sessions = new GameSessionRepositoryImpl();
const levels = new LevelRepositoryImpl(new ProceduralForestLevelDataSource());
new StartGameUseCase(levels, sessions).execute();
const gameState = new GetGameStateUseCase(sessions);

const viewModel = new ForestViewModel({
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
