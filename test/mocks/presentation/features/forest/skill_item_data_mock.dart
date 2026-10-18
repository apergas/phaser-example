import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/layers/presentation/features/forest/models/skill_item_data.dart';

abstract final class SkillItemDataMock {
  static const int maxLevel = 3;

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

  static SkillItemData get doubleStrikeAtLevelOne => learned(
    SkillId.doubleStrike,
    level: 1,
    reasonText: Internationalize.forestMissing(amounts: _amounts(gold: 90, mana: 30)),
    canLearn: false,
  );

  static SkillItemData get doubleStrikeAtLevelOneUpgradable =>
      learned(SkillId.doubleStrike, level: 1, reasonText: null, canLearn: true);

  static SkillItemData get doubleStrikeAtLevelTwo => learned(
    SkillId.doubleStrike,
    level: 2,
    reasonText: Internationalize.forestMissing(amounts: _amounts(gold: 135, mana: 45)),
    canLearn: false,
  );

  static SkillItemData get doubleStrikeMaxed => SkillItemData(
    id: SkillId.doubleStrike,
    name: Internationalize.forestSkillName(id: SkillId.doubleStrike),
    description: Internationalize.forestSkillDescription(id: SkillId.doubleStrike, level: maxLevel),
    levelText: Internationalize.forestHeroSkillLevel(level: maxLevel, max: maxLevel),
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
    doubleStrikeAtLevelOne,
    unaffordable(SkillId.dodge, missingGold: 90, missingMana: 30),
    unaffordable(SkillId.secondWind, missingGold: 130, missingMana: 45),
  ];

  static SkillItemData learned(SkillId id, {required int level, required String? reasonText, required bool canLearn}) {
    final next = _price(id, level: level + 1);
    return SkillItemData(
      id: id,
      name: Internationalize.forestSkillName(id: id),
      description: Internationalize.forestSkillDescription(id: id, level: level),
      levelText: Internationalize.forestHeroSkillLevel(level: level, max: maxLevel),
      nextText: Internationalize.forestHeroSkillNext(
        level: level + 1,
        effect: Internationalize.forestSkillDescription(id: id, level: level + 1),
      ),
      costText: _amounts(gold: next.gold, mana: next.mana),
      reasonText: reasonText,
      buttonText: Internationalize.forestHeroUpgrade,
      isKnown: true,
      canLearn: canLearn,
    );
  }

  static SkillItemData _make(SkillId id, {required String? reasonText, required bool canLearn}) => SkillItemData(
    id: id,
    name: Internationalize.forestSkillName(id: id),
    description: Internationalize.forestSkillDescription(id: id, level: 1),
    costText: _amounts(gold: _price(id, level: 1).gold, mana: _price(id, level: 1).mana),
    reasonText: reasonText,
    buttonText: Internationalize.forestHeroLearn,
    isKnown: false,
    canLearn: canLearn,
  );

  static ({int gold, int mana}) _price(SkillId id, {required int level}) => switch ((id, level)) {
    (SkillId.doubleStrike, 1) => (gold: 60, mana: 20),
    (SkillId.doubleStrike, 2) => (gold: 90, mana: 30),
    (SkillId.doubleStrike, _) => (gold: 135, mana: 45),
    (SkillId.dodge, 1) => (gold: 90, mana: 30),
    (SkillId.dodge, 2) => (gold: 135, mana: 45),
    (SkillId.dodge, _) => (gold: 205, mana: 70),
    (SkillId.secondWind, 1) => (gold: 130, mana: 45),
    (SkillId.secondWind, 2) => (gold: 195, mana: 70),
    (SkillId.secondWind, _) => (gold: 295, mana: 100),
  };

  static String _amounts({required int gold, required int mana}) => [
    Internationalize.forestAmount(resource: Resource.gold, amount: gold),
    Internationalize.forestAmount(resource: Resource.mana, amount: mana),
  ].join(', ');
}
