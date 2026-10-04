import * as Phaser from 'phaser';
import { ForestWebController } from 'rpg-shared';
import { ForestScene } from './presentation/screens/forest/ForestScene';
import { Hud } from './presentation/screens/forest/hud/Hud';
import { PreloadScene } from './presentation/screens/preload/PreloadScene';

// Composition root: game logic comes from the shared Kotlin module; this app only draws.
const controller = new ForestWebController();

const app = document.querySelector<HTMLElement>('#app');
if (!app) throw new Error('Missing #app container');

const hud = new Hud(app, controller.labels(), { build: (blueprint) => controller.requestBuild(blueprint) });
const forestScene = new ForestScene({ controller, hud });

const game = new Phaser.Game({
  type: Phaser.AUTO,
  backgroundColor: '#0e150e',
  pixelArt: true,
  scale: { mode: Phaser.Scale.RESIZE, parent: app, width: '100%', height: '100%' },
  scene: [new PreloadScene(ForestScene.KEY), forestScene],
});

// Dev-only handle for browser automation (e2e checks); stripped from production builds.
if (import.meta.env.DEV) {
  Object.assign(window, { __rpg: { game, controller } });
}
