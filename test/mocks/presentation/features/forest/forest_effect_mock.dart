import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

abstract final class ForestEffectMock {
  static TreeFelledEffect get treeFelled => TreeFelledEffect(treeId: 'tree-1', fromX: 180);

  static TreeFelledEffect get treeFelledCopy => TreeFelledEffect(treeId: 'tree-1', fromX: 180);

  static TreeHitEffect get treeHit => TreeHitEffect(treeId: 'tree-1', fromX: 180);

  static const ItemPickedUpEffect axePickedUp = ItemPickedUpEffect(itemId: 'axe-1');

  static const BuildingCompletedEffect buildingCompleted = BuildingCompletedEffect(buildingId: 'building-1');

  static const GearPurchasedEffect shortSwordPurchased = GearPurchasedEffect(gear: GearId.shortSword);

  static const GearPurchasedEffect shortSwordPurchasedCopy = GearPurchasedEffect(gear: GearId.shortSword);

  static const GearPurchasedEffect leatherArmorPurchased = GearPurchasedEffect(gear: GearId.leatherArmor);

  static const SkillLearnedEffect doubleStrikeLearned = SkillLearnedEffect(skill: SkillId.doubleStrike);

  static const SkillLearnedEffect doubleStrikeLearnedCopy = SkillLearnedEffect(skill: SkillId.doubleStrike);

  static const SkillLearnedEffect dodgeLearned = SkillLearnedEffect(skill: SkillId.dodge);
}
