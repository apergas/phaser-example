import * as Phaser from 'phaser';
import { seededRandom } from '../../../shared/seededRandom';
import type { Hud } from '../../dom/Hud';
import type { Effect, GameViewModel } from '../../viewmodels/GameViewModel';
import { CAMERA_ZOOM, ForestAtlas } from '../assets';
import { BuildingView, addHouseImage, placeHouseImage } from '../views/BuildingView';
import { Depth } from '../views/depth';
import { GroundView } from '../views/GroundView';
import { ItemView } from '../views/ItemView';
import { PlayerView } from '../views/PlayerView';
import { TreeView } from '../views/TreeView';

export interface ForestSceneDependencies {
  readonly viewModel: GameViewModel;
  readonly hud: Hud;
}

const CAMERA_LERP = 0.1;
const TREE_VARIANT_SEED = 7;
/** Area around the spawn point kept clear of decor so the player does not start on top of it. */
const SPAWN_CLEARANCE = 48;
const GHOST_ALPHA = 0.6;
const GHOST_VALID_TINT = 0xb8ffb8;
const GHOST_INVALID_TINT = 0xff8080;

/**
 * Passive Phaser view of the game. It forwards input to the `GameViewModel`, draws its state every
 * frame and plays the effects it returns. It only decides engine matters: sprites, hit-testing,
 * camera and tweens.
 */
export class ForestScene extends Phaser.Scene {
  static readonly KEY = 'ForestScene';

  private readonly vm: GameViewModel;
  private readonly hud: Hud;
  private playerView!: PlayerView;
  private ghost: Phaser.GameObjects.Image | null = null;
  private readonly trees = new Map<string, TreeView>();
  private readonly items = new Map<string, ItemView>();
  private readonly buildings = new Map<string, BuildingView>();
  /** Non-solid ground sprites (decor, stumps) that a new building should clear away. */
  private clutter: Phaser.GameObjects.Image[] = [];

  constructor(deps: ForestSceneDependencies) {
    super(ForestScene.KEY);
    this.vm = deps.viewModel;
    this.hud = deps.hud;
  }

  create(): void {
    const world = this.vm.world();
    const spawn = this.vm.player.state.position;

    const random = seededRandom(TREE_VARIANT_SEED);
    for (const tree of world.trees) {
      const frame = ForestAtlas.TREES[Math.floor(random() * ForestAtlas.TREES.length)];
      this.trees.set(tree.id, new TreeView(this, tree.position, frame));
    }
    for (const item of world.items) this.items.set(item.id, new ItemView(this, item.position));
    for (const building of world.buildings) {
      this.buildings.set(building.id, new BuildingView(this, building.position, building.progress));
    }

    const spawnArea = new Phaser.Geom.Rectangle(
      spawn.x - SPAWN_CLEARANCE,
      spawn.y - SPAWN_CLEARANCE * 2,
      SPAWN_CLEARANCE * 2,
      SPAWN_CLEARANCE * 3,
    );
    const occupied = [spawnArea, ...[...this.trees.values(), ...this.items.values()].map((view) => view.bounds)];
    this.clutter = [...new GroundView(this, world.width, world.height, occupied).decor];
    this.playerView = new PlayerView(this, spawn);

    this.setUpCamera(world.width, world.height);
    this.setUpInput();
  }

  update(_time: number, delta: number): void {
    this.vm.tick(delta).forEach((effect) => this.play(effect));
    if (this.vm.placement) this.vm.pointerMoved(this.pointerInWorld());

    this.playerView.render(this.vm.player.state);
    this.hud.render(this.vm.hud.state);
    this.renderGhost();
  }

  private play(effect: Effect): void {
    switch (effect.kind) {
      case 'item-picked-up':
        this.items.get(effect.itemId)?.pickUp();
        this.items.delete(effect.itemId);
        break;
      case 'tree-hit':
        this.trees.get(effect.treeId)?.hit(effect.fromX);
        break;
      case 'tree-felled': {
        const stump = this.trees.get(effect.treeId)?.fell(effect.fromX);
        if (stump) this.clutter.push(stump);
        this.trees.delete(effect.treeId);
        break;
      }
      case 'building-placed': {
        const { building } = effect;
        const view = new BuildingView(this, building.position, building.progress);
        this.buildings.set(building.id, view);
        this.clearClutterUnder(view.bounds);
        break;
      }
      case 'building-hammered':
        this.buildings.get(effect.buildingId)?.hammered(effect.progress);
        break;
      case 'building-completed':
        this.buildings.get(effect.buildingId)?.complete();
        break;
    }
  }

  private setUpInput(): void {
    this.input.mouse?.disableContextMenu();
    this.input.keyboard?.on('keydown-ESC', () => this.vm.cancel());

    this.input.on(Phaser.Input.Events.POINTER_DOWN, (pointer: Phaser.Input.Pointer) => {
      const point = { x: pointer.worldX, y: pointer.worldY };
      const button = pointer.rightButtonDown() ? 'secondary' : 'primary';
      this.vm.mapClicked(point, this.treeAt(point.x, point.y), button).forEach((effect) => this.play(effect));
    });
  }

  /** Draws the placement preview from the view model, creating or removing it as needed. */
  private renderGhost(): void {
    const placement = this.vm.placement;
    if (!placement) {
      this.ghost?.destroy();
      this.ghost = null;
      return;
    }

    this.ghost ??= addHouseImage(this, placement.position).setAlpha(GHOST_ALPHA);
    placeHouseImage(this.ghost, placement.position)
      .setTint(placement.valid ? GHOST_VALID_TINT : GHOST_INVALID_TINT)
      .setDepth(Depth.OVERLAY);
  }

  private pointerInWorld(): { x: number; y: number } {
    const pointer = this.input.activePointer;
    const point = this.cameras.main.getWorldPoint(pointer.x, pointer.y);
    return { x: point.x, y: point.y };
  }

  /** The tree drawn on top at this point, so overlapping canopies resolve to the front one. */
  private treeAt(x: number, y: number): string | null {
    let best: { id: string; depth: number } | null = null;
    for (const [id, view] of this.trees) {
      if (view.containsPoint(x, y) && (!best || view.depth > best.depth)) best = { id, depth: view.depth };
    }
    return best?.id ?? null;
  }

  private clearClutterUnder(area: Phaser.Geom.Rectangle): void {
    this.clutter = this.clutter.filter((sprite) => {
      if (!area.contains(sprite.x, sprite.y)) return true;
      sprite.destroy();
      return false;
    });
  }

  private setUpCamera(worldWidth: number, worldHeight: number): void {
    const camera = this.cameras.main;
    camera.setZoom(CAMERA_ZOOM);
    camera.startFollow(this.playerView.followTarget, true, CAMERA_LERP, CAMERA_LERP);

    // Keeps the camera inside the world. On an axis where the viewport is larger than the world,
    // bounds grow symmetrically so the world stays centred instead of stuck to the top-left corner.
    const fitBounds = () => {
      const viewWidth = this.scale.gameSize.width / CAMERA_ZOOM;
      const viewHeight = this.scale.gameSize.height / CAMERA_ZOOM;
      camera.setBounds(
        Math.min(0, (worldWidth - viewWidth) / 2),
        Math.min(0, (worldHeight - viewHeight) / 2),
        Math.max(worldWidth, viewWidth),
        Math.max(worldHeight, viewHeight),
      );
    };
    fitBounds();
    this.scale.on(Phaser.Scale.Events.RESIZE, fitBounds);
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => this.scale.off(Phaser.Scale.Events.RESIZE, fitBounds));
  }
}
