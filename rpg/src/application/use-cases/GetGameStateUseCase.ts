import { type Blueprint, Blueprints } from '../../domain/entities/Blueprint';
import type { Activity } from '../../domain/entities/Player';
import type { World } from '../../domain/entities/World';
import type { QuestLog } from '../../domain/quests/QuestLog';
import { Rules } from '../../domain/rules';
import type { Position } from '../../domain/value-objects/Position';
import type { BuildOptionDto, PlayerStateDto, PointDto, QuestDto, WorldSnapshotDto } from '../dto';

/** Read-only queries over the world, mapped to DTOs for the adapters. */
export class GetGameStateUseCase {
  private readonly world: World;
  private readonly questLog: QuestLog;

  constructor(world: World, questLog: QuestLog) {
    this.world = world;
    this.questLog = questLog;
  }

  quests(): QuestDto[] {
    const statuses = this.questLog.status(this.world);
    const currentId = statuses.find((quest) => !quest.completed)?.id;
    return statuses.map((quest) => ({ ...quest, current: quest.id === currentId }));
  }

  player(): PlayerStateDto {
    const { player } = this.world;
    const activity = player.activity;

    return {
      position: toPoint(player.position),
      activity: activity.kind,
      target: this.targetOf(activity),
      swingProgress: swingProgressOf(activity),
      wood: player.inventory.wood,
      hasAxe: player.inventory.hasTool('axe'),
    };
  }

  buildOptions(): BuildOptionDto[] {
    const wood = this.world.player.inventory.wood;
    return Object.values<Blueprint>(Blueprints).map((blueprint) => ({
      blueprintId: blueprint.id,
      woodCost: blueprint.woodCost,
      affordable: wood >= blueprint.woodCost,
    }));
  }

  snapshot(): WorldSnapshotDto {
    return {
      width: this.world.width,
      height: this.world.height,
      trees: this.world.trees.map((tree) => ({ id: tree.id, position: toPoint(tree.position) })),
      items: this.world.items.map((item) => ({ id: item.id, kind: item.kind, position: toPoint(item.position) })),
      buildings: this.world.buildings.map((building) => ({
        id: building.id,
        blueprintId: building.blueprint.id,
        position: toPoint(building.position),
        progress: building.progress,
      })),
    };
  }

  private targetOf(activity: Activity): PointDto | null {
    if (activity.kind === 'walking') return toPoint(activity.destination);
    if (activity.kind === 'chopping') {
      const tree = this.world.trees.find((candidate) => candidate.id === activity.treeId);
      return tree ? toPoint(tree.position) : null;
    }
    if (activity.kind === 'constructing') {
      const building = this.world.buildings.find((candidate) => candidate.id === activity.buildingId);
      return building ? toPoint(building.position) : null;
    }
    return null;
  }
}

function swingProgressOf(activity: Activity): number {
  if (activity.kind === 'chopping') return activity.elapsedMs / Rules.CHOP_INTERVAL_MS;
  if (activity.kind === 'constructing') return activity.elapsedMs / Rules.HAMMER_INTERVAL_MS;
  return 0;
}

function toPoint(position: Position): PointDto {
  return { x: position.x, y: position.y };
}
