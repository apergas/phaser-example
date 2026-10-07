import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/forest/models/skill_item_data.dart';

abstract final class SkillItemDataMock {
  static SkillItemData needsTower(SkillId id) => _make(
    id,
    reasonText: Internationalize.forestHeroNeedsBuilding(
      name: Internationalize.forestBlueprint(id: BlueprintId.mageTower),
    ),
    canLearn: false,
  );

  static SkillItemData unaffordable(SkillId id, {required int missingGold}) => _make(
    id,
    reasonText: Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.gold, amount: missingGold),
    ),
    canLearn: false,
  );

  static SkillItemData get doubleStrikeAvailable => _make(SkillId.doubleStrike, reasonText: null, canLearn: true);

  static SkillItemData get doubleStrikeKnown => SkillItemData(
    id: SkillId.doubleStrike,
    name: Internationalize.forestSkillName(id: SkillId.doubleStrike),
    description: Internationalize.forestSkillDescription(id: SkillId.doubleStrike),
    isKnown: true,
    canLearn: false,
  );

  static List<SkillItemData> get withoutTower => [
    needsTower(SkillId.doubleStrike),
    needsTower(SkillId.dodge),
    needsTower(SkillId.secondWind),
  ];

  static List<SkillItemData> get readyToLearnDoubleStrike => [
    doubleStrikeAvailable,
    unaffordable(SkillId.dodge, missingGold: 30),
    unaffordable(SkillId.secondWind, missingGold: 70),
  ];

  static List<SkillItemData> get afterLearningDoubleStrike => [
    doubleStrikeKnown,
    unaffordable(SkillId.dodge, missingGold: 90),
    unaffordable(SkillId.secondWind, missingGold: 130),
  ];

  static SkillItemData _make(SkillId id, {required String? reasonText, required bool canLearn}) => SkillItemData(
    id: id,
    name: Internationalize.forestSkillName(id: id),
    description: Internationalize.forestSkillDescription(id: id),
    costText: Internationalize.forestAmount(resource: Resource.gold, amount: _price(id)),
    reasonText: reasonText,
    isKnown: false,
    canLearn: canLearn,
  );

  static int _price(SkillId id) => switch (id) {
    SkillId.doubleStrike => 60,
    SkillId.secondWind => 130,
    SkillId.dodge => 90,
  };
}
