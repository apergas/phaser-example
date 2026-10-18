import '../../../../../core/config/constants/enum/gear_id.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';
import '../../../../../core/config/constants/enum/upgrade_id.dart';
import '../../../../domain/entities/building/building_entity.dart';

sealed class ForestEffect {
  const ForestEffect();
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

  final int wood;

  const TreeFelledEffect({required this.treeId, required this.fromX, required this.wood});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeFelledEffect && other.treeId == treeId && other.fromX == fromX && other.wood == wood;

  @override
  int get hashCode => Object.hash(TreeFelledEffect, treeId, fromX, wood);
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

final class GearPurchasedEffect extends ForestEffect {
  final GearId gear;

  const GearPurchasedEffect({required this.gear});

  @override
  bool operator ==(Object other) => identical(this, other) || other is GearPurchasedEffect && other.gear == gear;

  @override
  int get hashCode => Object.hash(GearPurchasedEffect, gear);
}

final class SkillLearnedEffect extends ForestEffect {
  final SkillId skill;

  const SkillLearnedEffect({required this.skill});

  @override
  bool operator ==(Object other) => identical(this, other) || other is SkillLearnedEffect && other.skill == skill;

  @override
  int get hashCode => Object.hash(SkillLearnedEffect, skill);
}

final class TreeSproutedEffect extends ForestEffect {
  final String stumpId;

  const TreeSproutedEffect({required this.stumpId});

  @override
  bool operator ==(Object other) => identical(this, other) || other is TreeSproutedEffect && other.stumpId == stumpId;

  @override
  int get hashCode => Object.hash(TreeSproutedEffect, stumpId);
}

final class TreeRegrownEffect extends ForestEffect {
  final String treeId;

  const TreeRegrownEffect({required this.treeId});

  @override
  bool operator ==(Object other) => identical(this, other) || other is TreeRegrownEffect && other.treeId == treeId;

  @override
  int get hashCode => Object.hash(TreeRegrownEffect, treeId);
}

final class RockHitEffect extends ForestEffect {
  final String rockId;
  final double fromX;

  const RockHitEffect({required this.rockId, required this.fromX});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RockHitEffect && other.rockId == rockId && other.fromX == fromX;

  @override
  int get hashCode => Object.hash(RockHitEffect, rockId, fromX);
}

final class RockBrokenEffect extends ForestEffect {
  final String rockId;
  final int stone;

  const RockBrokenEffect({required this.rockId, required this.stone});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RockBrokenEffect && other.rockId == rockId && other.stone == stone;

  @override
  int get hashCode => Object.hash(RockBrokenEffect, rockId, stone);
}

final class UpgradePurchasedEffect extends ForestEffect {
  final UpgradeId upgrade;

  const UpgradePurchasedEffect({required this.upgrade});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UpgradePurchasedEffect && other.upgrade == upgrade;

  @override
  int get hashCode => Object.hash(UpgradePurchasedEffect, upgrade);
}
