import * as Phaser from 'phaser';
import type { AdvanceWorldUseCase } from '../../../application/use-cases/AdvanceWorldUseCase';
import type { ChopTreeUseCase } from '../../../application/use-cases/ChopTreeUseCase';
import type { ConstructBuildingUseCase } from '../../../application/use-cases/ConstructBuildingUseCase';
import type { GetGameStateUseCase } from '../../../application/use-cases/GetGameStateUseCase';
import type { MovePlayerToUseCase } from '../../../application/use-cases/MovePlayerToUseCase';
import type { BlueprintId } from '../../../domain/entities/Blueprint';
import type { GameEvent } from '../../../domain/events';
import { seededRandom } from '../../../shared/seededRandom';
import type { HudPort } from '../../dom/Hud';
import { Labels } from '../../labels';
import { CAMERA_ZOOM, ForestAtlas } from '../assets';
import { BuildingView, addHouseImage, placeHouseImage } from '../views/BuildingView';
import { Depth } from '../views/depth';
import { GroundView } from '../views/GroundView';
import { ItemView } from '../views/ItemView';
import { PlayerView } from '../views/PlayerView';
import { TreeView } from '../views/TreeView';

export interface ForestSceneDependencies {
  readonly movePlayerTo: MovePlayerToUseCase;
  readonly chopTree: ChopTreeUseCase;
  readonly constructBuilding: ConstructBuildingUseCase;
  readonly advanceWorld: AdvanceWorldUseCase;
  readonly gameState: GetGameStateUseCase;
  readonly hud: HudPort;
}

const CAMERA_LERP = 0.1;
const TREE_VARIANT_SEED = 7;
/** Area around the spawn point kept clear of decor so the player does not start on top of it. */
const SPAWN_CLEARANCE = 48;
const GHOST_ALPHA = 0.6;
const GHOST_VALID_TINT = 0xb8ffb8;
const GHOST_INVALID_TINT = 0xff8080;

/** Phaser adapter: translates input into use cases and renders their results. No game rules here. */
export class ForestScene extends Phaser.Scene {
  static readonly KEY = 'ForestScene';

  private readonly deps: ForestSceneDependencies;
  private playerView!: PlayerView;
  private readonly trees = new Map<string, TreeView>();
  private readonly items = new Map<string, ItemView>();
  private readonly buildings = new Map<string, BuildingView>();
  /** Non-solid ground sprites (decor, stumps) that a new building should clear away. */
  private clutter: Phaser.GameObjects.Image[] = [];
  private placing: { blueprintId: BlueprintId; ghost: Phaser.GameObjects.Image } | null = null;

  constructor(deps: ForestSceneDependencies) {
    super(ForestScene.KEY);
    this.deps = deps;
  }

  create(): void {
    const world = this.deps.gameState.snapshot();
    const player = this.deps.gameState.player();

    const random = seededRandom(TREE_VARIANT_SEED);
    for (const tree of world.trees) {
      const frame = ForestAtlas.TREES[Math.floor(random() * ForestAtlas.TREES.length)];
      this.trees.set(tree.id, new TreeView(this, tree.position, frame));
    }
    for (const item of world.items) this.items.set(item.id, new ItemView(this, item.position));

    const spawnArea = new Phaser.Geom.Rectangle(
      player.position.x - SPAWN_CLEARANCE,
      player.position.y - SPAWN_CLEARANCE * 2,
      SPAWN_CLEARANCE * 2,
      SPAWN_CLEARANCE * 3,
    );
    const occupied = [spawnArea, ...[...this.trees.values(), ...this.items.values()].map((view) => view.bounds)];
    this.clutter = [...new GroundView(this, world.width, world.height, occupied).decor];
    this.playerView = new PlayerView(this, player.position);

    this.setUpCamera(world.width, world.height);
    this.setUpInput();
    this.deps.hud.showMessage(Labels.messages.welcome);
  }

  update(_time: number, delta: number): void {
    this.deps.advanceWorld.execute(delta).forEach((event) => this.handle(event));

    const player = this.deps.gameState.player();
    this.playerView.render(player);
    this.deps.hud.update(player, this.deps.gameState.buildOptions(), this.deps.gameState.quests());
    this.updateGhost();
  }

  /** Called by the HUD: the next click on the map places a building of this kind. */
  startPlacing(blueprintId: BlueprintId): void {
    this.cancelPlacing();
    const ghost = addHouseImage(this, { x: 0, y: 0 }).setAlpha(GHOST_ALPHA).setDepth(Depth.OVERLAY);
    this.placing = { blueprintId, ghost };
    this.updateGhost();
    this.deps.hud.setPlacing(blueprintId);
    this.deps.hud.showMessage(Labels.messages.placing(Labels.blueprints[blueprintId]));
  }

  private cancelPlacing(): void {
    this.placing?.ghost.destroy();
    this.placing = null;
    this.deps.hud.setPlacing(null);
  }

  private handle(event: GameEvent): void {
    const playerX = this.deps.gameState.player().position.x;

    switch (event.type) {
      case 'item-picked-up':
        this.items.get(event.itemId)?.pickUp();
        this.items.delete(event.itemId);
        this.deps.hud.showMessage(Labels.messages.pickedUpAxe);
        break;
      case 'player-blocked':
        this.deps.hud.showMessage(Labels.messages.blockedPath);
        break;
      case 'tree-hit':
        this.trees.get(event.treeId)?.hit(playerX);
        break;
      case 'tree-felled': {
        const stump = this.trees.get(event.treeId)?.fell(playerX);
        if (stump) this.clutter.push(stump);
        this.trees.delete(event.treeId);
        this.deps.hud.showMessage(Labels.messages.woodGained(event.wood));
        break;
      }
      case 'building-hammered':
        this.buildings.get(event.buildingId)?.hammered(event.progress);
        break;
      case 'building-completed':
        this.buildings.get(event.buildingId)?.complete();
        this.deps.hud.showMessage(Labels.messages.buildingCompleted(Labels.blueprints.house));
        break;
      case 'quest-completed': {
        const allDone = this.deps.gameState.quests().every((quest) => quest.completed);
        this.deps.hud.showMessage(
          allDone
            ? Labels.messages.allQuestsCompleted
            : Labels.messages.questCompleted(Labels.questTitles[event.questId]),
        );
        break;
      }
    }
  }

  private setUpInput(): void {
    this.input.mouse?.disableContextMenu();
    this.input.keyboard?.on('keydown-ESC', () => this.cancelPlacing());

    this.input.on(Phaser.Input.Events.POINTER_DOWN, (pointer: Phaser.Input.Pointer) => {
      const { worldX: x, worldY: y } = pointer;

      if (this.placing) {
        if (pointer.rightButtonDown()) this.cancelPlacing();
        else this.placeBuilding(this.placing.blueprintId, x, y);
        return;
      }

      const treeId = this.treeAt(x, y);
      if (treeId) {
        if (this.deps.chopTree.execute(treeId) === 'no-axe') this.deps.hud.showMessage(Labels.messages.needAxe);
        return;
      }
      this.deps.movePlayerTo.execute(x, y);
    });
  }

  private placeBuilding(blueprintId: BlueprintId, x: number, y: number): void {
    const result = this.deps.constructBuilding.execute(blueprintId, x, y);
    if (!result.ok) {
      if (result.reason === 'blocked') return this.deps.hud.showMessage(Labels.messages.blocked);
      this.deps.hud.showMessage(Labels.messages.notEnoughWood);
      return this.cancelPlacing();
    }

    const { building } = result;
    const view = new BuildingView(this, building.position, building.progress);
    this.buildings.set(building.id, view);
    this.clearClutterUnder(view.bounds);
    this.cancelPlacing();
    this.deps.hud.showMessage(Labels.messages.buildingStarted);
  }

  private clearClutterUnder(area: Phaser.Geom.Rectangle): void {
    this.clutter = this.clutter.filter((sprite) => {
      if (!area.contains(sprite.x, sprite.y)) return true;
      sprite.destroy();
      return false;
    });
  }

  /** Moves the placement preview under the pointer, tinted by whether the site is free. */
  private updateGhost(): void {
    if (!this.placing) return;
    const { blueprintId, ghost } = this.placing;
    const pointer = this.input.activePointer;
    const point = this.cameras.main.getWorldPoint(pointer.x, pointer.y);

    placeHouseImage(ghost, point);
    const valid = this.deps.constructBuilding.canPlace(blueprintId, point.x, point.y);
    ghost.setTint(valid ? GHOST_VALID_TINT : GHOST_INVALID_TINT).setDepth(Depth.OVERLAY);
  }

  /** The tree drawn on top at this point, so overlapping canopies resolve to the front one. */
  private treeAt(x: number, y: number): string | null {
    let best: { id: string; depth: number } | null = null;
    for (const [id, view] of this.trees) {
      if (view.containsPoint(x, y) && (!best || view.depth > best.depth)) best = { id, depth: view.depth };
    }
    return best?.id ?? null;
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
