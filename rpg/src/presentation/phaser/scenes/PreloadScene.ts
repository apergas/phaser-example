import * as Phaser from 'phaser';
import {
  CHARACTER_FRAME_SIZE,
  CharacterSheets,
  FACING_DIRECTIONS,
  ForestAtlas,
  GeneratedTextures,
  IdleSheet,
  Sheets,
  TILE_SIZE,
  WalkSheet,
  WorkSheet,
  WorkSheets,
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
    for (const sheet of Object.values(CharacterSheets)) {
      this.load.spritesheet(sheet.key, sheet.url, { frameWidth: CHARACTER_FRAME_SIZE, frameHeight: CHARACTER_FRAME_SIZE });
    }
    for (const sheet of Object.values(WorkSheets)) {
      this.load.spritesheet(sheet.key, sheet.url, { frameWidth: WorkSheet.FRAME_SIZE, frameHeight: WorkSheet.FRAME_SIZE });
    }
    this.load.atlas(ForestAtlas.key, ForestAtlas.textureUrl, ForestAtlas.atlasUrl);
  }

  create(): void {
    this.registerHeroAnimations(false, CharacterSheets.WALK.key, CharacterSheets.IDLE.key);
    this.registerHeroAnimations(true, CharacterSheets.WALK_AXE.key, CharacterSheets.IDLE_AXE.key);
    this.generateParticleTextures();
    this.scene.start(this.nextSceneKey);
  }

  private registerHeroAnimations(withAxe: boolean, walkKey: string, idleKey: string): void {
    FACING_DIRECTIONS.forEach((direction, row) => {
      this.anims.create({
        key: heroAnimationKey('walk', direction, withAxe),
        frames: this.anims.generateFrameNumbers(walkKey, {
          start: row * WalkSheet.COLUMNS + WalkSheet.FIRST_STEP,
          end: row * WalkSheet.COLUMNS + WalkSheet.LAST_STEP,
        }),
        frameRate: WalkSheet.FRAME_RATE,
        repeat: -1,
      });
      this.anims.create({
        key: heroAnimationKey('idle', direction, withAxe),
        frames: this.anims.generateFrameNumbers(idleKey, {
          start: row * IdleSheet.COLUMNS,
          end: row * IdleSheet.COLUMNS + IdleSheet.COLUMNS - 1,
        }),
        frameRate: IdleSheet.FRAME_RATE,
        repeat: -1,
      });
    });
  }

  private generateParticleTextures(): void {
    const graphics = this.make.graphics({}, false);
    graphics.fillStyle(0x8a5a2b).fillRect(0, 0, 3, 2).fillStyle(0xc89a5e).fillRect(0, 0, 2, 1);
    graphics.generateTexture(GeneratedTextures.WOOD_CHIP, 3, 2);
    graphics.clear().fillStyle(0xd8cdb0).fillCircle(3, 3, 3);
    graphics.generateTexture(GeneratedTextures.DUST, 6, 6);
    graphics.destroy();
  }
}
