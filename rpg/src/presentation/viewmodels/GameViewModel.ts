import type { BlueprintKey, BuildingDto, GameEventDto, PointDto, WorldSnapshotDto } from '../../application/dto';
import type { AdvanceWorldUseCase } from '../../application/use-cases/AdvanceWorldUseCase';
import type { ChopTreeUseCase } from '../../application/use-cases/ChopTreeUseCase';
import type { ConstructBuildingUseCase } from '../../application/use-cases/ConstructBuildingUseCase';
import type { GetGameStateUseCase } from '../../application/use-cases/GetGameStateUseCase';
import type { MovePlayerToUseCase } from '../../application/use-cases/MovePlayerToUseCase';
import { Labels } from '../labels';
import { HudViewModel } from './HudViewModel';
import { PlayerViewModel } from './PlayerViewModel';

export interface GameUseCases {
  readonly movePlayerTo: MovePlayerToUseCase;
  readonly chopTree: ChopTreeUseCase;
  readonly constructBuilding: ConstructBuildingUseCase;
  readonly advanceWorld: AdvanceWorldUseCase;
  readonly gameState: GetGameStateUseCase;
}

/** One-off visual reactions the view should play (animations, particles). */
export type Effect =
  | { readonly kind: 'item-picked-up'; readonly itemId: string }
  | { readonly kind: 'tree-hit'; readonly treeId: string; readonly fromX: number }
  | { readonly kind: 'tree-felled'; readonly treeId: string; readonly fromX: number }
  | { readonly kind: 'building-placed'; readonly building: BuildingDto }
  | { readonly kind: 'building-hammered'; readonly buildingId: string; readonly progress: number }
  | { readonly kind: 'building-completed'; readonly buildingId: string };

/** A building being positioned with the pointer, before it is ordered. */
export interface Placement {
  readonly blueprint: BlueprintKey;
  readonly position: PointDto;
  readonly valid: boolean;
}

/**
 * Presentation logic for the gameplay screen, free of Phaser and the DOM: what a click means,
 * the placement mode, which message to show for each event, and the display state of the HUD
 * and the player. The scene feeds it input and draws its state and effects.
 */
export class GameViewModel {
  readonly hud = new HudViewModel();
  readonly player = new PlayerViewModel();
  private readonly useCases: GameUseCases;
  private placing: Placement | null = null;

  constructor(useCases: GameUseCases) {
    this.useCases = useCases;
    this.refresh();
    this.hud.showMessage(Labels.messages.welcome);
  }

  get placement(): Placement | null {
    return this.placing;
  }

  /** The world as it is now, to build the initial scene. */
  world(): WorldSnapshotDto {
    return this.useCases.gameState.snapshot();
  }

  /** Advances the game; returns the effects to play this frame. */
  tick(deltaMs: number): Effect[] {
    const fromX = this.useCases.gameState.player().position.x;
    const effects = this.useCases.advanceWorld.execute(deltaMs).flatMap((event) => this.react(event, fromX));
    this.refresh();
    return effects;
  }

  /**
   * A click on the map. `treeId` is the tree drawn under the pointer, if any: hit-testing sprites
   * is the view's job. Secondary clicks cancel placement.
   */
  mapClicked(point: PointDto, treeId: string | null, button: 'primary' | 'secondary' = 'primary'): Effect[] {
    if (this.placing) {
      if (button === 'secondary') this.cancel();
      else return this.place(this.placing.blueprint, point);
      return [];
    }
    if (button === 'secondary') return [];

    if (treeId) {
      if (this.useCases.chopTree.execute(treeId) === 'no-axe') this.hud.showMessage(Labels.messages.needAxe);
    } else {
      this.useCases.movePlayerTo.execute(point.x, point.y);
    }
    return [];
  }

  pointerMoved(point: PointDto): void {
    if (!this.placing) return;
    const { blueprint } = this.placing;
    this.placing = { blueprint, position: point, valid: this.useCases.constructBuilding.canPlace(blueprint, point.x, point.y) };
  }

  /**
   * From the build menu: the next click on the map places this building. The preview starts on the
   * player until the view reports the pointer through `pointerMoved`.
   */
  requestBuild(blueprint: BlueprintKey): void {
    const option = this.useCases.gameState.buildOptions().find((candidate) => candidate.blueprintId === blueprint);
    if (!option?.affordable) return this.hud.showMessage(Labels.messages.notEnoughWood);

    this.placing = { blueprint, position: this.player.state.position, valid: false };
    this.pointerMoved(this.player.state.position);
    this.hud.showMessage(Labels.messages.placing(Labels.blueprints[blueprint]));
    this.refresh();
  }

  cancel(): void {
    this.placing = null;
    this.refresh();
  }

  private place(blueprint: BlueprintKey, point: PointDto): Effect[] {
    const result = this.useCases.constructBuilding.execute(blueprint, point.x, point.y);
    if (!result.ok) {
      if (result.reason === 'blocked') {
        this.hud.showMessage(Labels.messages.blocked);
      } else {
        this.hud.showMessage(Labels.messages.notEnoughWood);
        this.cancel();
      }
      return [];
    }

    this.cancel();
    this.hud.showMessage(Labels.messages.buildingStarted);
    return [{ kind: 'building-placed', building: result.building }];
  }

  private react(event: GameEventDto, fromX: number): Effect[] {
    switch (event.type) {
      case 'item-picked-up':
        this.hud.showMessage(Labels.messages.pickedUpAxe);
        return [{ kind: 'item-picked-up', itemId: event.itemId }];
      case 'player-blocked':
        this.hud.showMessage(Labels.messages.blockedPath);
        return [];
      case 'tree-hit':
        return [{ kind: 'tree-hit', treeId: event.treeId, fromX }];
      case 'tree-felled':
        this.hud.showMessage(Labels.messages.woodGained(event.wood));
        return [{ kind: 'tree-felled', treeId: event.treeId, fromX }];
      case 'building-hammered':
        return [{ kind: 'building-hammered', buildingId: event.buildingId, progress: event.progress }];
      case 'building-completed':
        this.hud.showMessage(Labels.messages.buildingCompleted(Labels.blueprints[event.blueprintId]));
        return [{ kind: 'building-completed', buildingId: event.buildingId }];
      case 'quest-completed': {
        const allDone = this.useCases.gameState.quests().every((quest) => quest.completed);
        this.hud.showMessage(
          allDone ? Labels.messages.allQuestsCompleted : Labels.messages.questCompleted(Labels.questTitles[event.questId]),
        );
        return [];
      }
    }
  }

  private refresh(): void {
    const { gameState } = this.useCases;
    const player = gameState.player();
    this.player.update(player);
    this.hud.update(player, gameState.buildOptions(), gameState.quests(), this.placing !== null);
  }
}
