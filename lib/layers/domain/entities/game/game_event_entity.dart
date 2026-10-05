import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../core/config/constants/enum/quest_id.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';

sealed class GameEventEntity {
  const GameEventEntity();
}

final class ItemPickedUpEventEntity extends GameEventEntity {
  final String itemId;
  final ToolKind kind;

  const ItemPickedUpEventEntity({required this.itemId, required this.kind});

  @override
  bool operator ==(Object other) => other is ItemPickedUpEventEntity && other.itemId == itemId && other.kind == kind;

  @override
  int get hashCode => Object.hash(ItemPickedUpEventEntity, itemId, kind);
}

final class PlayerBlockedEventEntity extends GameEventEntity {
  const PlayerBlockedEventEntity();

  @override
  bool operator ==(Object other) => other is PlayerBlockedEventEntity;

  @override
  int get hashCode => (PlayerBlockedEventEntity).hashCode;
}

final class TreeHitEventEntity extends GameEventEntity {
  final String treeId;
  final int hitsRemaining;

  const TreeHitEventEntity({required this.treeId, required this.hitsRemaining});

  @override
  bool operator ==(Object other) =>
      other is TreeHitEventEntity && other.treeId == treeId && other.hitsRemaining == hitsRemaining;

  @override
  int get hashCode => Object.hash(TreeHitEventEntity, treeId, hitsRemaining);
}

final class TreeFelledEventEntity extends GameEventEntity {
  final String treeId;
  final int wood;

  const TreeFelledEventEntity({required this.treeId, required this.wood});

  @override
  bool operator ==(Object other) => other is TreeFelledEventEntity && other.treeId == treeId && other.wood == wood;

  @override
  int get hashCode => Object.hash(TreeFelledEventEntity, treeId, wood);
}

final class BuildingHammeredEventEntity extends GameEventEntity {
  final String buildingId;
  final double progress;

  const BuildingHammeredEventEntity({required this.buildingId, required this.progress});

  @override
  bool operator ==(Object other) =>
      other is BuildingHammeredEventEntity && other.buildingId == buildingId && other.progress == progress;

  @override
  int get hashCode => Object.hash(BuildingHammeredEventEntity, buildingId, progress);
}

final class BuildingCompletedEventEntity extends GameEventEntity {
  final String buildingId;
  final BlueprintId blueprint;

  const BuildingCompletedEventEntity({required this.buildingId, required this.blueprint});

  @override
  bool operator ==(Object other) =>
      other is BuildingCompletedEventEntity && other.buildingId == buildingId && other.blueprint == blueprint;

  @override
  int get hashCode => Object.hash(BuildingCompletedEventEntity, buildingId, blueprint);
}

final class QuestCompletedEventEntity extends GameEventEntity {
  final QuestId questId;

  const QuestCompletedEventEntity({required this.questId});

  @override
  bool operator ==(Object other) => other is QuestCompletedEventEntity && other.questId == questId;

  @override
  int get hashCode => Object.hash(QuestCompletedEventEntity, questId);
}
