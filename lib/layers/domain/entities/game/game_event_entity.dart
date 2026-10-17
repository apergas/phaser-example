import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../core/config/constants/enum/quest_id.dart';
import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../tree/tree_entity.dart';

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

final class TreeSproutedEventEntity extends GameEventEntity {
  final String stumpId;

  const TreeSproutedEventEntity({required this.stumpId});

  @override
  bool operator ==(Object other) => other is TreeSproutedEventEntity && other.stumpId == stumpId;

  @override
  int get hashCode => Object.hash(TreeSproutedEventEntity, stumpId);
}

final class TreeRegrownEventEntity extends GameEventEntity {
  final TreeEntity tree;

  const TreeRegrownEventEntity({required this.tree});

  @override
  bool operator ==(Object other) => other is TreeRegrownEventEntity && other.tree == tree;

  @override
  int get hashCode => Object.hash(TreeRegrownEventEntity, tree);
}

final class RockHitEventEntity extends GameEventEntity {
  final String rockId;

  const RockHitEventEntity({required this.rockId});

  @override
  bool operator ==(Object other) => other is RockHitEventEntity && other.rockId == rockId;

  @override
  int get hashCode => Object.hash(RockHitEventEntity, rockId);
}

final class RockBrokenEventEntity extends GameEventEntity {
  final String rockId;
  final int stone;

  const RockBrokenEventEntity({required this.rockId, required this.stone});

  @override
  bool operator ==(Object other) => other is RockBrokenEventEntity && other.rockId == rockId && other.stone == stone;

  @override
  int get hashCode => Object.hash(RockBrokenEventEntity, rockId, stone);
}

final class DepositedEventEntity extends GameEventEntity {
  final String buildingId;
  final Map<Resource, int> load;

  const DepositedEventEntity({required this.buildingId, required this.load});

  @override
  bool operator ==(Object other) =>
      other is DepositedEventEntity &&
      other.buildingId == buildingId &&
      const MapEquality<Resource, int>().equals(other.load, load);

  @override
  int get hashCode => Object.hash(DepositedEventEntity, buildingId, const MapEquality<Resource, int>().hash(load));
}
