import '../../../../domain/entities/building/building_entity.dart';

sealed class ForestEffect {
  const ForestEffect();
}

final class ItemPickedUpEffect extends ForestEffect {
  final String itemId;

  const ItemPickedUpEffect({required this.itemId});

  @override
  bool operator ==(Object other) => identical(this, other) || other is ItemPickedUpEffect && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(ItemPickedUpEffect, itemId);
}

final class TreeHitEffect extends ForestEffect {
  final String treeId;
  final double fromX;

  const TreeHitEffect({required this.treeId, required this.fromX});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TreeHitEffect && other.treeId == treeId && other.fromX == fromX;

  @override
  int get hashCode => Object.hash(TreeHitEffect, treeId, fromX);
}

final class TreeFelledEffect extends ForestEffect {
  final String treeId;
  final double fromX;

  const TreeFelledEffect({required this.treeId, required this.fromX});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TreeFelledEffect && other.treeId == treeId && other.fromX == fromX;

  @override
  int get hashCode => Object.hash(TreeFelledEffect, treeId, fromX);
}

final class BuildingPlacedEffect extends ForestEffect {
  final BuildingEntity building;

  const BuildingPlacedEffect({required this.building});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BuildingPlacedEffect && other.building == building;

  @override
  int get hashCode => Object.hash(BuildingPlacedEffect, building);
}

final class BuildingHammeredEffect extends ForestEffect {
  final String buildingId;
  final double progress;

  const BuildingHammeredEffect({required this.buildingId, required this.progress});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuildingHammeredEffect && other.buildingId == buildingId && other.progress == progress;

  @override
  int get hashCode => Object.hash(BuildingHammeredEffect, buildingId, progress);
}

final class BuildingCompletedEffect extends ForestEffect {
  final String buildingId;

  const BuildingCompletedEffect({required this.buildingId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BuildingCompletedEffect && other.buildingId == buildingId;

  @override
  int get hashCode => Object.hash(BuildingCompletedEffect, buildingId);
}
