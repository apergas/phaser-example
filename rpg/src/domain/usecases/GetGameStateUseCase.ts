import { type Blueprint, Blueprints } from '../entities/Blueprint';
import type { Activity, IntentKind } from '../entities/Player';
import type { BuildOption } from './models/BuildOption';
import type { ActivityKind, PlayerState } from './models/PlayerState';
import type { QuestProgress } from './models/QuestProgress';
import type { WorldSnapshot } from './models/WorldSnapshot';
import { toBlueprintKey, toPoint, toQuestKey, toToolKey } from './models/mappers';
import type { GameSessionRepository } from '../repositories/GameSessionRepository';

/** How each kind of work is shown to adapters. */
const WORK_ACTIVITY: Record<IntentKind, ActivityKind> = { chop: 'chopping', construct: 'constructing' };

/** Read-only queries over the current game, returned as application models for the adapters. */
export class GetGameStateUseCase {
  private readonly sessions: GameSessionRepository;

  constructor(sessions: GameSessionRepository) {
    this.sessions = sessions;
  }

  player(): PlayerState {
    const { world } = this.sessions.current();
    const { player } = world;
    const target = world.playerTarget;

    return {
      position: toPoint(player.position),
      activity: activityKind(player.activity),
      target: target ? toPoint(target) : null,
      swingProgress: world.workProgress,
      wood: player.inventory.wood,
      hasAxe: player.inventory.hasTool('axe'),
    };
  }

  buildOptions(): BuildOption[] {
    const wood = this.sessions.current().world.player.inventory.wood;
    return Object.values<Blueprint>(Blueprints).map((blueprint) => ({
      blueprintId: toBlueprintKey(blueprint.id),
      woodCost: blueprint.woodCost,
      affordable: wood >= blueprint.woodCost,
    }));
  }

  quests(): QuestProgress[] {
    const { world, quests } = this.sessions.current();
    const statuses = quests.status(world);
    const currentId = statuses.find((quest) => !quest.completed)?.id;
    return statuses.map((quest) => ({
      id: toQuestKey(quest.id),
      progress: quest.progress,
      target: quest.target,
      completed: quest.completed,
      current: quest.id === currentId,
    }));
  }

  snapshot(): WorldSnapshot {
    const { world } = this.sessions.current();
    return {
      width: world.width,
      height: world.height,
      trees: world.trees.map((tree) => ({ id: tree.id, position: toPoint(tree.position) })),
      items: world.items.map((item) => ({ id: item.id, kind: toToolKey(item.kind), position: toPoint(item.position) })),
      buildings: world.buildings.map((building) => ({
        id: building.id,
        blueprintId: toBlueprintKey(building.blueprint.id),
        position: toPoint(building.position),
        progress: building.progress,
      })),
    };
  }
}

function activityKind(activity: Activity): ActivityKind {
  return activity.kind === 'working' ? WORK_ACTIVITY[activity.intent.kind] : activity.kind;
}
