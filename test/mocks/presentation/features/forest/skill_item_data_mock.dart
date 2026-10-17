import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/presentation/features/forest/models/skill_item_data.dart';

abstract final class SkillItemDataMock {
  static SkillItemData needsTower(SkillId id) => _make(
    id,
    reasonText: Internationalize.forestHeroNeedsBuilding(
      name: Internationalize.forestBlueprint(id: BlueprintId.mageTower),
    ),
    canLearn: false,
  );

  static SkillItemData unaffordable(SkillId id, {required int missingGold, required int missingMana}) => _make(
    id,
    reasonText: Internationalize.forestMissing(
      amounts: _amounts(gold: missingGold, mana: missingMana),
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
    unaffordable(SkillId.dodge, missingGold: 30, missingMana: 10),
    unaffordable(SkillId.secondWind, missingGold: 70, missingMana: 25),
  ];

  static List<SkillItemData> get afterLearningDoubleStrike => [
    doubleStrikeKnown,
    unaffordable(SkillId.dodge, missingGold: 90, missingMana: 30),
    unaffordable(SkillId.secondWind, missingGold: 130, missingMana: 45),
  ];

  static SkillItemData _make(SkillId id, {required String? reasonText, required bool canLearn}) => SkillItemData(
    id: id,
    name: Internationalize.forestSkillName(id: id),
    description: Internationalize.forestSkillDescription(id: id),
    costText: _amounts(gold: _price(id).gold, mana: _price(id).mana),
    reasonText: reasonText,
    isKnown: false,
    canLearn: canLearn,
  );

  static ({int gold, int mana}) _price(SkillId id) => switch (id) {
    SkillId.doubleStrike => (gold: 60, mana: 20),
    SkillId.secondWind => (gold: 130, mana: 45),
    SkillId.dodge => (gold: 90, mana: 30),
  };

  static String _amounts({required int gold, required int mana}) => [
    Internationalize.forestAmount(resource: Resource.gold, amount: gold),
    Internationalize.forestAmount(resource: Resource.mana, amount: mana),
  ].join(', ');
}
