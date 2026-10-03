import * as Phaser from 'phaser';
import {
  CHARACTER_FRAME_SIZE,
  FACING_DIRECTIONS,
  ForestAtlas,
  IdleSheet,
  Sheets,
  TILE_SIZE,
  WalkSheet,
} from '../assets';
import { heroAnimationKey } from '../views/PlayerView';

/** Loads every texture once, registers animations, then hands over to gameplay. */
export class PreloadScene extends Phaser.Scene {
  static readonly KEY = 'PreloadScene';

  private readonly nextSceneKey: string;

  constructor(nextSceneKey: string) {
    super(PreloadScene.KEY);
    this.nextSceneKey = nextSceneKey;
  }

  preload(): void {
    this.load.spritesheet(Sheets.GROUND.key, Sheets.GROUND.url, { frameWidth: TILE_SIZE, frameHeight: TILE_SIZE });
    for (const sheet of [Sheets.HERO_WALK, Sheets.HERO_IDLE]) {
      this.load.spritesheet(sheet.key, sheet.url, {
        frameWidth: CHARACTER_FRAME_SIZE,
        frameHeight: CHARACTER_FRAME_SIZE,
      });
    }
    this.load.atlas(ForestAtlas.key, ForestAtlas.textureUrl, ForestAtlas.atlasUrl);
  }

  create(): void {
    this.registerHeroAnimations();
    this.scene.start(this.nextSceneKey);
  }

  private registerHeroAnimations(): void {
    FACING_DIRECTIONS.forEach((direction, row) => {
      this.anims.create({
        key: heroAnimationKey('walk', direction),
        frames: this.anims.generateFrameNumbers(Sheets.HERO_WALK.key, {
          start: row * WalkSheet.COLUMNS + WalkSheet.FIRST_STEP,
          end: row * WalkSheet.COLUMNS + WalkSheet.LAST_STEP,
        }),
        frameRate: WalkSheet.FRAME_RATE,
        repeat: -1,
      });
      this.anims.create({
        key: heroAnimationKey('idle', direction),
        frames: this.anims.generateFrameNumbers(Sheets.HERO_IDLE.key, {
          start: row * IdleSheet.COLUMNS,
          end: row * IdleSheet.COLUMNS + IdleSheet.COLUMNS - 1,
        }),
        frameRate: IdleSheet.FRAME_RATE,
        repeat: -1,
      });
    });
  }
}
