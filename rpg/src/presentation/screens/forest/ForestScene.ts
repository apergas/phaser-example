import * as Phaser from 'phaser';
import type { ForestWebController, WebEffect, WebPlacement } from 'rpg-shared';
import { CAMERA_ZOOM } from '../../common/assets';
import { Depth } from '../../common/depth';
import type { Hud } from './hud/Hud';
import { PlayerView } from './player/PlayerView';
import { BuildingView, addHouseImage, placeHouseImage } from './world/BuildingView';
import { GroundView } from './world/GroundView';
import { ItemView } from './world/ItemView';
import { TreeView } from './world/TreeView';

export interface ForestSceneDependencies {
  readonly controller: ForestWebController;
  readonly hud: Hud;
}

const CAMERA_LERP = 0.1;
const GHOST_ALPHA = 0.6;
const GHOST_VALID_TINT = 0xb8ffb8;
const GHOST_INVALID_TINT = 0xff8080;

/**
 * Passive Phaser view of the game. Each frame: advance the shared view model, play the effects it
 * returns, draw its state. It only decides engine matters: sprites, hit-testing, camera and tweens.
 */
export class ForestScene extends Phaser.Scene {
  static readonly KEY = 'ForestScene';

  private readonly controller: ForestWebController;
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
    this.controller = deps.controller;
    this.hud = deps.hud;
  }

  create(): void {
    const world = this.controller.world();
    const spawn = this.controller.state().player.position;

    // What to draw and where comes from the level (shared): no art decisions are made here.
    for (const tree of world.trees) this.trees.set(tree.id, new TreeView(this, tree.position, tree.frame));
    for (const item of world.items) this.items.set(item.id, new ItemView(this, item.position));
    for (const building of world.buildings) {
      this.buildings.set(building.id, new BuildingView(this, building.position, building.progress));
    }

    this.clutter = [...new GroundView(this, world.width, world.height, world.decorations).decor];
    this.playerView = new PlayerView(this, spawn);

    this.setUpCamera(world.width, world.height);
    this.setUpInput();
  }

  update(_time: number, delta: number): void {
    if (this.controller.state().placement) {
      const pointer = this.pointerInWorld();
      this.controller.pointerMoved(pointer.x, pointer.y);
    }
    this.controller.tick(delta);
    this.controller.takeEffects().forEach((effect) => this.play(effect));

    const state = this.controller.state();
    this.playerView.render(state.player);
    this.hud.render(state.hud);
    this.renderGhost(state.placement);
  }

  private play(effect: WebEffect): void {
    switch (effect.kind) {
      case 'message':
        if (effect.text) this.hud.showMessage(effect.text);
        break;
      case 'item-picked-up':
        this.items.get(effect.id ?? '')?.pickUp();
        this.items.delete(effect.id ?? '');
        break;
      case 'tree-hit':
        this.trees.get(effect.id ?? '')?.hit(effect.fromX);
        break;
      case 'tree-felled': {
        const stump = this.trees.get(effect.id ?? '')?.fell(effect.fromX);
        if (stump) this.clutter.push(stump);
        this.trees.delete(effect.id ?? '');
        break;
      }
      case 'building-placed': {
        if (!effect.building) break;
        const view = new BuildingView(this, effect.building.position, effect.building.progress);
        this.buildings.set(effect.building.id, view);
        this.clearClutterUnder(view.bounds);
        break;
      }
      case 'building-hammered':
        this.buildings.get(effect.id ?? '')?.hammered(effect.progress);
        break;
      case 'building-completed':
        this.buildings.get(effect.id ?? '')?.complete();
        break;
    }
  }

  private setUpInput(): void {
    this.input.mouse?.disableContextMenu();
    this.input.keyboard?.on('keydown-ESC', () => this.controller.cancelPlacement());

    this.input.on(Phaser.Input.Events.POINTER_DOWN, (pointer: Phaser.Input.Pointer) => {
      const { worldX: x, worldY: y } = pointer;
      this.controller.mapClicked(x, y, this.treeAt(x, y), pointer.rightButtonDown());
      this.controller.takeEffects().forEach((effect) => this.play(effect));
    });
  }

  /** Draws the placement preview, creating or removing it as needed. */
  private renderGhost(placement: WebPlacement | null | undefined): void {
    if (!placement) {
      this.ghost?.destroy();
      this.ghost = null;
      return;
    }
    this.ghost ??= addHouseImage(this, placement.position).setAlpha(GHOST_ALPHA);
    placeHouseImage(this.ghost, placement.position)
      .setTint(placement.isValid ? GHOST_VALID_TINT : GHOST_INVALID_TINT)
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

    // Keeps the camera inside the world; a world smaller than the window stays centred.
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
