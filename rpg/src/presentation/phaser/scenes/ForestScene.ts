import * as Phaser from 'phaser';
import type { AdvanceWorldUseCase } from '../../../application/use-cases/AdvanceWorldUseCase';
import type { MovePlayerToUseCase } from '../../../application/use-cases/MovePlayerToUseCase';
import type { Position } from '../../../domain/value-objects/Position';
import { seededRandom } from '../../../shared/seededRandom';
import { CAMERA_ZOOM, ForestAtlas } from '../assets';
import { GroundView } from '../views/GroundView';
import { PlayerView } from '../views/PlayerView';
import { TreeView } from '../views/TreeView';

export interface ForestSceneDependencies {
  readonly width: number;
  readonly height: number;
  readonly initialPlayerPosition: Position;
  readonly treePositions: readonly Position[];
  readonly movePlayerTo: MovePlayerToUseCase;
  readonly advanceWorld: AdvanceWorldUseCase;
}

const CAMERA_LERP = 0.1;
const TREE_VARIANT_SEED = 7;
/** Area around the spawn point kept clear of decor so the player does not start on top of it. */
const SPAWN_CLEARANCE = 48;

/** Phaser adapter: translates input into use cases and renders their results. No game rules here. */
export class ForestScene extends Phaser.Scene {
  static readonly KEY = 'ForestScene';

  private readonly deps: ForestSceneDependencies;
  private playerView!: PlayerView;

  constructor(deps: ForestSceneDependencies) {
    super(ForestScene.KEY);
    this.deps = deps;
  }

  create(): void {
    const random = seededRandom(TREE_VARIANT_SEED);
    const trees = this.deps.treePositions.map((position) => {
      const frame = ForestAtlas.TREES[Math.floor(random() * ForestAtlas.TREES.length)];
      return new TreeView(this, position, frame);
    });
    const spawn = this.deps.initialPlayerPosition;
    const spawnArea = new Phaser.Geom.Rectangle(
      spawn.x - SPAWN_CLEARANCE,
      spawn.y - SPAWN_CLEARANCE * 2,
      SPAWN_CLEARANCE * 2,
      SPAWN_CLEARANCE * 3,
    );
    new GroundView(this, this.deps.width, this.deps.height, [spawnArea, ...trees.map((tree) => tree.bounds)]);
    this.playerView = new PlayerView(this, this.deps.initialPlayerPosition);

    this.cameras.main.setZoom(CAMERA_ZOOM);
    this.cameras.main.startFollow(this.playerView.followTarget, true, CAMERA_LERP, CAMERA_LERP);
    this.fitCameraBounds();
    this.scale.on(Phaser.Scale.Events.RESIZE, this.fitCameraBounds, this);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      this.scale.off(Phaser.Scale.Events.RESIZE, this.fitCameraBounds, this);
    });

    this.input.on(Phaser.Input.Events.POINTER_DOWN, (pointer: Phaser.Input.Pointer) => {
      this.deps.movePlayerTo.execute(pointer.worldX, pointer.worldY);
    });
  }

  /**
   * Keeps the camera inside the world. On an axis where the viewport is larger than the world,
   * bounds grow symmetrically so the world stays centred instead of stuck to the top-left corner.
   */
  private fitCameraBounds(): void {
    // Visible area in world units: the zoom makes it smaller than the canvas.
    const viewWidth = this.scale.gameSize.width / CAMERA_ZOOM;
    const viewHeight = this.scale.gameSize.height / CAMERA_ZOOM;
    const { width, height } = this.deps;

    this.cameras.main.setBounds(
      Math.min(0, (width - viewWidth) / 2),
      Math.min(0, (height - viewHeight) / 2),
      Math.max(width, viewWidth),
      Math.max(height, viewHeight),
    );
  }

  update(_time: number, delta: number): void {
    this.playerView.render(this.deps.advanceWorld.execute(delta));
  }
}
