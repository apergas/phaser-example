part of 'forest_bloc.dart';

sealed class ForestEvent {
  const ForestEvent();
}

final class ForestStarted extends ForestEvent {
  const ForestStarted();
}

final class ForestTicked extends ForestEvent {
  final double deltaMs;

  const ForestTicked({required this.deltaMs});
}

final class ForestMapClicked extends ForestEvent {
  final PositionEntity position;
  final String? treeId;
  final String? buildingId;
  final String? rockId;
  final bool isSecondary;

  const ForestMapClicked({
    required this.position,
    this.treeId,
    this.buildingId,
    this.rockId,
    this.isSecondary = false,
  });
}

final class ForestPointerMoved extends ForestEvent {
  final PositionEntity position;

  const ForestPointerMoved({required this.position});
}

final class ForestBuildRequested extends ForestEvent {
  final BlueprintId blueprint;

  const ForestBuildRequested({required this.blueprint});
}

final class ForestPlacementCancelled extends ForestEvent {
  const ForestPlacementCancelled();
}

final class ForestGearPurchaseRequested extends ForestEvent {
  final GearId gear;

  const ForestGearPurchaseRequested({required this.gear});
}

final class ForestArenaRequested extends ForestEvent {
  const ForestArenaRequested();
}

final class ForestSkillLearnRequested extends ForestEvent {
  final SkillId skill;

  const ForestSkillLearnRequested({required this.skill});
}

final class ForestUpgradeRequested extends ForestEvent {
  final UpgradeId upgrade;

  const ForestUpgradeRequested({required this.upgrade});
}
