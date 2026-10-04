import type { BlueprintId } from '../domain/entities/Blueprint';
import type { ToolKind } from '../domain/entities/Inventory';
import type { GameEvent } from '../domain/events';
import type { QuestId } from '../domain/quests/QuestLog';
import type { Position } from '../domain/value-objects/Position';
import type { World } from '../domain/world/World';
import type { BlueprintKey, GameEventDto, PointDto, QuestKey, ToolKey } from './dto';

/*
 * Identifier conversions. They are plain assignments, so they cost nothing at runtime, but each
 * pair only compiles while the domain and DTO unions are identical: adding a blueprint, tool or
 * quest on one side without the other is a type error here.
 */
export const toBlueprintKey = (id: BlueprintId): BlueprintKey => id;
export const toBlueprintId = (key: BlueprintKey): BlueprintId => key;
export const toToolKey = (kind: ToolKind): ToolKey => kind;
export const toToolKind = (key: ToolKey): ToolKind => key;
export const toQuestKey = (id: QuestId): QuestKey => id;
export const toQuestId = (key: QuestKey): QuestId => key;

export function toPoint(position: Position): PointDto {
  return { x: position.x, y: position.y };
}

/** Converts a domain event, adding whatever adapters need that the event itself does not carry. */
export function toEventDto(event: GameEvent, world: World): GameEventDto {
  switch (event.type) {
    case 'item-picked-up':
      return { type: event.type, itemId: event.itemId, kind: toToolKey(event.kind) };
    case 'player-blocked':
      return { type: event.type };
    case 'tree-hit':
      return { type: event.type, treeId: event.treeId, hitsRemaining: event.hitsRemaining };
    case 'tree-felled':
      return { type: event.type, treeId: event.treeId, wood: event.wood };
    case 'building-hammered':
      return { type: event.type, buildingId: event.buildingId, progress: event.progress };
    case 'building-completed': {
      const building = world.buildings.find((candidate) => candidate.id === event.buildingId);
      if (!building) throw new Error(`Completed building ${event.buildingId} not found`);
      return { type: event.type, buildingId: event.buildingId, blueprintId: toBlueprintKey(building.blueprint.id) };
    }
    case 'quest-completed':
      return { type: event.type, questId: toQuestKey(event.questId) };
  }
}
