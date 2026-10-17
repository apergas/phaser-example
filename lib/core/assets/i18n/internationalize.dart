import 'package:easy_localization/easy_localization.dart';

import '../../config/constants/enum/arena_level_id.dart';
import '../../config/constants/enum/blueprint_id.dart';
import '../../config/constants/enum/construction_rejection.dart';
import '../../config/constants/enum/enemy_kind.dart';
import '../../config/constants/enum/fight_advice.dart';
import '../../config/constants/enum/forest/hero_panel_section.dart';
import '../../config/constants/enum/gear_id.dart';
import '../../config/constants/enum/gear_slot.dart';
import '../../config/constants/enum/quest_id.dart';
import '../../config/constants/enum/quest_line.dart';
import '../../config/constants/enum/resource.dart';
import '../../config/constants/enum/skill_id.dart';
import '../../config/constants/enum/tool_kind.dart';
import '../../config/constants/enum/upgrade_id.dart';

class Internationalize {
  static const String _app = 'app';
  static String get appTitle => '$_app.title'.tr();

  static const String _common = 'common';
  static String get commonError => '$_common.error'.tr();
  static String get commonAccept => '$_common.accept'.tr();

  static const String _error = 'error';
  static String get errorGenericTitle => '$_error.genericTitle'.tr();
  static String get errorGenericMessage => '$_error.genericMessage'.tr();
  static String get errorInvalidLevelTitle => '$_error.invalidLevelTitle'.tr();
  static String errorInvalidLevelMessage({required String reason}) =>
      '$_error.invalidLevelMessage'.tr(namedArgs: {'reason': reason});
  static String get errorUnknownTreeKindTitle => '$_error.unknownTreeKindTitle'.tr();
  static String errorUnknownTreeKindMessage({required String detail}) =>
      '$_error.unknownTreeKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorUnknownDecorationKindTitle => '$_error.unknownDecorationKindTitle'.tr();
  static String errorUnknownDecorationKindMessage({required String detail}) =>
      '$_error.unknownDecorationKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorUnknownItemKindTitle => '$_error.unknownItemKindTitle'.tr();
  static String errorUnknownItemKindMessage({required String detail}) =>
      '$_error.unknownItemKindMessage'.tr(namedArgs: {'detail': detail});
  static String get errorNoGameInProgressTitle => '$_error.noGameInProgressTitle'.tr();
  static String get errorNoGameInProgressMessage => '$_error.noGameInProgressMessage'.tr();
  static String get errorInvalidSaveTitle => '$_error.invalidSaveTitle'.tr();
  static String errorInvalidSaveMessage({required String reason}) =>
      '$_error.invalidSaveMessage'.tr(namedArgs: {'reason': reason});

  static const String _forest = 'forest';
  static String forestResource({required Resource resource}) => switch (resource) {
    Resource.wood => '$_forest.resource.wood'.tr(),
    Resource.gold => '$_forest.resource.gold'.tr(),
    Resource.mana => '$_forest.resource.mana'.tr(),
    Resource.stone => '$_forest.resource.stone'.tr(),
  };
  static String forestTool({required ToolKind tool}) => switch (tool) {
    ToolKind.axe => '$_forest.tool.axe'.tr(),
    ToolKind.pickaxe => '$_forest.tool.pickaxe'.tr(),
  };
  static String get forestBuild => '$_forest.hud.build'.tr();
  static String get forestQuests => '$_forest.hud.quests'.tr();
  static String get forestArena => '$_forest.hud.arena'.tr();
  static String get forestWorkshop => '$_forest.hud.workshop'.tr();
  static String get forestGame => '$_forest.hud.game'.tr();
  static String get forestGameSave => '$_forest.game.save'.tr();
  static String get forestGameSaved => '$_forest.game.saved'.tr();
  static String get forestGameNewGame => '$_forest.game.newGame'.tr();
  static String get forestGameNewGameConfirm => '$_forest.game.newGameConfirm'.tr();
  static String get forestGameConfirm => '$_forest.game.confirm'.tr();
  static String get forestGameCancel => '$_forest.game.cancel'.tr();
  static String get forestStock => '$_forest.hud.stock'.tr();
  static String forestCarry({required int amount, required int capacity}) =>
      '$_forest.hud.carry'.tr(namedArgs: {'amount': '$amount', 'capacity': '$capacity'});
  static String get forestQuestDone => '$_forest.hud.questDone'.tr();
  static String forestQuestsDone({required int count}) =>
      '$_forest.hud.questsDone'.plural(count, namedArgs: {'count': '$count'});
  static String forestAmount({required Resource resource, required int amount}) => switch (resource) {
    Resource.wood => '$_forest.amount.wood'.tr(namedArgs: {'amount': '$amount'}),
    Resource.gold => '$_forest.amount.gold'.tr(namedArgs: {'amount': '$amount'}),
    Resource.mana => '$_forest.amount.mana'.tr(namedArgs: {'amount': '$amount'}),
    Resource.stone => '$_forest.amount.stone'.tr(namedArgs: {'amount': '$amount'}),
  };
  static String forestMissing({required String amounts}) => '$_forest.hud.missing'.tr(namedArgs: {'amounts': amounts});
  static String forestBlueprint({required BlueprintId id}) => switch (id) {
    BlueprintId.house => '$_forest.blueprint.house'.tr(),
    BlueprintId.forge => '$_forest.blueprint.forge'.tr(),
    BlueprintId.armory => '$_forest.blueprint.armory'.tr(),
    BlueprintId.mageTower => '$_forest.blueprint.mageTower'.tr(),
    BlueprintId.camp => '$_forest.blueprint.camp'.tr(),
    BlueprintId.storehouse => '$_forest.blueprint.storehouse'.tr(),
    BlueprintId.quarry => '$_forest.blueprint.quarry'.tr(),
    BlueprintId.workshop => '$_forest.blueprint.workshop'.tr(),
  };
  static String forestQuestTitle({required QuestId id}) => switch (id) {
    QuestId.gatherWood => '$_forest.quest.gatherWood'.tr(),
    QuestId.buildHouse => '$_forest.quest.buildHouse'.tr(),
    QuestId.buildForge => '$_forest.quest.buildForge'.tr(),
    QuestId.winFirstFight => '$_forest.quest.winFirstFight'.tr(),
    QuestId.buyFirstWeapon => '$_forest.quest.buyFirstWeapon'.tr(),
    QuestId.buildArmory => '$_forest.quest.buildArmory'.tr(),
    QuestId.buildMageTower => '$_forest.quest.buildMageTower'.tr(),
    QuestId.learnASkill => '$_forest.quest.learnASkill'.tr(),
    QuestId.clearHalfArena => '$_forest.quest.clearHalfArena'.tr(),
    QuestId.becomeChampion => '$_forest.quest.becomeChampion'.tr(),
    QuestId.fellTenTrees => '$_forest.quest.fellTenTrees'.tr(),
    QuestId.fellAnOak => '$_forest.quest.fellAnOak'.tr(),
    QuestId.gatherFortyWood => '$_forest.quest.gatherFortyWood'.tr(),
    QuestId.buildTwoHouses => '$_forest.quest.buildTwoHouses'.tr(),
    QuestId.seeATreeRegrow => '$_forest.quest.seeATreeRegrow'.tr(),
    QuestId.gatherTwentyStone => '$_forest.quest.gatherTwentyStone'.tr(),
    QuestId.buildQuarry => '$_forest.quest.buildQuarry'.tr(),
    QuestId.buildWorkshop => '$_forest.quest.buildWorkshop'.tr(),
    QuestId.upgradeAxe => '$_forest.quest.upgradeAxe'.tr(),
  };
  static String forestQuestLine({required QuestLine line}) => switch (line) {
    QuestLine.village => '$_forest.questLine.village'.tr(),
    QuestLine.hero => '$_forest.questLine.hero'.tr(),
  };
  static String get forestMessageWelcome => '$_forest.message.welcome'.tr();
  static String get forestMessageNeedAxe => '$_forest.message.needAxe'.tr();
  static String get forestMessageNeedPickaxe => '$_forest.message.needPickaxe'.tr();
  static String get forestMessageBlockedPath => '$_forest.message.blockedPath'.tr();
  static String get forestMessagePickedUpAxe => '$_forest.message.pickedUpAxe'.tr();
  static String get forestMessagePickedUpAxeTouch => '$_forest.message.pickedUpAxeTouch'.tr();
  static String get forestMessagePickedUpPickaxe => '$_forest.message.pickedUpPickaxe'.tr();
  static String get forestMessagePickedUpPickaxeTouch => '$_forest.message.pickedUpPickaxeTouch'.tr();
  static String get forestMessageBlockedSite => '$_forest.message.blockedSite'.tr();
  static String get forestMessageNotEnoughResources => '$_forest.message.notEnoughResources'.tr();
  static String get forestMessageBuildingStarted => '$_forest.message.buildingStarted'.tr();
  static String forestMessageQuestLineCompleted({required QuestLine line}) =>
      '$_forest.message.questLineCompleted'.tr(namedArgs: {'line': forestQuestLine(line: line)});
  static String forestMessageWoodGained({required int wood}) =>
      '$_forest.message.woodGained'.tr(namedArgs: {'wood': '$wood'});
  static String forestMessageStoneGained({required int amount}) =>
      '$_forest.message.stoneGained'.tr(namedArgs: {'amount': '$amount'});
  static String get forestMessageCarryFull => '$_forest.message.carryFull'.tr();
  static String forestMessageDeposited({required String amounts}) =>
      '$_forest.message.deposited'.tr(namedArgs: {'amounts': amounts});
  static String get forestMessageNothingToDeposit => '$_forest.message.nothingToDeposit'.tr();
  static String forestMessagePlacing({required String name}) =>
      '$_forest.message.placing'.tr(namedArgs: {'name': name});
  static String forestMessagePlacingTouch({required String name}) =>
      '$_forest.message.placingTouch'.tr(namedArgs: {'name': name});
  static String forestMessageBuildingCompleted({required String name}) =>
      '$_forest.message.buildingCompleted'.tr(namedArgs: {'name': name});
  static String forestMessageQuestCompleted({required String title}) =>
      '$_forest.message.questCompleted'.tr(namedArgs: {'title': title});
  static String get forestPlacementConfirm => '$_forest.placement.confirm'.tr();
  static String get forestPlacementCancel => '$_forest.placement.cancel'.tr();
  static String forestPlacementRejection({required ConstructionRejection rejection}) => switch (rejection) {
    ConstructionRejection.notEnoughResources => forestMessageNotEnoughResources,
    ConstructionRejection.blocked => forestMessageBlockedSite,
    ConstructionRejection.needsNearbyRock => '$_forest.placement.needsRock'.tr(),
  };
  static String get forestAccessibilityGameWorld => '$_forest.accessibility.gameWorld'.tr();
  static String get forestRetry => '$_forest.retry'.tr();
  static String forestFloatingWoodGained({required int wood}) =>
      '$_forest.floating.woodGained'.tr(namedArgs: {'wood': '$wood'});
  static String forestFloatingStoneGained({required int amount}) =>
      '$_forest.floating.stoneGained'.tr(namedArgs: {'amount': '$amount'});
  static String get forestHero => '$_forest.hero.title'.tr();
  static String get forestHeroPower => '$_forest.hero.power'.tr();
  static String get forestHeroChampion => '$_forest.hero.champion'.tr();
  static String get forestHeroAttack => '$_forest.hero.attack'.tr();
  static String get forestHeroDefense => '$_forest.hero.defense'.tr();
  static String get forestHeroHealth => '$_forest.hero.health'.tr();
  static String forestHeroAttackRange({required int min, required int max}) =>
      '$_forest.hero.attackRange'.tr(namedArgs: {'min': '$min', 'max': '$max'});
  static String forestHeroWeaponStats({required int min, required int max}) =>
      '$_forest.hero.weaponStats'.tr(namedArgs: {'min': '$min', 'max': '$max'});
  static String forestHeroArmorStats({required int defense, required int health}) =>
      '$_forest.hero.armorStats'.tr(namedArgs: {'defense': '$defense', 'health': '$health'});
  static String forestHeroSlot({required GearSlot slot}) => switch (slot) {
    GearSlot.weapon => '$_forest.hero.slot.weapon'.tr(),
    GearSlot.armor => '$_forest.hero.slot.armor'.tr(),
  };
  static String forestHeroSection({required HeroPanelSection section}) => switch (section) {
    HeroPanelSection.gear => '$_forest.hero.section.gear'.tr(),
    HeroPanelSection.skills => '$_forest.hero.section.skills'.tr(),
  };
  static String get forestHeroEquipped => '$_forest.hero.equipped'.tr();
  static String get forestHeroBuy => '$_forest.hero.buy'.tr();
  static String forestHeroNeedsBuilding({required String name}) =>
      '$_forest.hero.needsBuilding'.tr(namedArgs: {'name': name});
  static String get forestHeroMaxed => '$_forest.hero.maxed'.tr();
  static String forestGear({required GearId id}) => switch (id) {
    GearId.woodcutterAxe => '$_forest.gear.woodcutterAxe'.tr(),
    GearId.shortSword => '$_forest.gear.shortSword'.tr(),
    GearId.ironSword => '$_forest.gear.ironSword'.tr(),
    GearId.steelSword => '$_forest.gear.steelSword'.tr(),
    GearId.workClothes => '$_forest.gear.workClothes'.tr(),
    GearId.leatherArmor => '$_forest.gear.leatherArmor'.tr(),
    GearId.chainMail => '$_forest.gear.chainMail'.tr(),
    GearId.plateArmor => '$_forest.gear.plateArmor'.tr(),
  };
  static String forestMessageGearPurchased({required String name}) =>
      '$_forest.message.gearPurchased'.tr(namedArgs: {'name': name});
  static String get forestMessageGearNotNextTier => '$_forest.message.gearNotNextTier'.tr();
  static String get forestHeroLearn => '$_forest.hero.learn'.tr();
  static String get forestHeroUpgrade => '$_forest.hero.upgrade'.tr();
  static String get forestHeroSkillMax => '$_forest.hero.skillMax'.tr();
  static String forestHeroSkillLevel({required int level, required int max}) =>
      '$_forest.hero.skillLevel'.tr(namedArgs: {'level': '$level', 'max': '$max'});
  static String forestHeroSkillNext({required int level, required String effect}) =>
      '$_forest.hero.skillNext'.tr(namedArgs: {'level': '$level', 'effect': effect});
  static String forestSkillName({required SkillId id}) => switch (id) {
    SkillId.doubleStrike => '$_forest.skill.doubleStrike.name'.tr(),
    SkillId.secondWind => '$_forest.skill.secondWind.name'.tr(),
    SkillId.dodge => '$_forest.skill.dodge.name'.tr(),
  };
  static String forestSkillDescription({required SkillId id, required int level}) => switch ((id, level)) {
    (SkillId.doubleStrike, 1) => '$_forest.skill.doubleStrike.description'.tr(),
    (SkillId.doubleStrike, 2) => '$_forest.skill.doubleStrike.descriptionLevel2'.tr(),
    (SkillId.doubleStrike, _) => '$_forest.skill.doubleStrike.descriptionLevel3'.tr(),
    (SkillId.secondWind, 1) => '$_forest.skill.secondWind.description'.tr(),
    (SkillId.secondWind, 2) => '$_forest.skill.secondWind.descriptionLevel2'.tr(),
    (SkillId.secondWind, _) => '$_forest.skill.secondWind.descriptionLevel3'.tr(),
    (SkillId.dodge, 1) => '$_forest.skill.dodge.description'.tr(),
    (SkillId.dodge, 2) => '$_forest.skill.dodge.descriptionLevel2'.tr(),
    (SkillId.dodge, _) => '$_forest.skill.dodge.descriptionLevel3'.tr(),
  };
  static String forestMessageSkillLearned({required String name}) =>
      '$_forest.message.skillLearned'.tr(namedArgs: {'name': name});
  static String forestMessageSkillUpgraded({required String name, required int level}) =>
      '$_forest.message.skillUpgraded'.tr(namedArgs: {'name': name, 'level': '$level'});
  static String get forestMessageSkillMaxLevel => '$_forest.message.skillMaxLevel'.tr();
  static String get forestUpgradeTitle => '$_forest.upgrade.title'.tr();
  static String forestUpgradeName({required UpgradeId id}) => switch (id) {
    UpgradeId.ironAxe => '$_forest.upgrade.ironAxe.name'.tr(),
    UpgradeId.ironPickaxe => '$_forest.upgrade.ironPickaxe.name'.tr(),
  };
  static String forestUpgradeEffect({required UpgradeId id, required int percent}) => switch (id) {
    UpgradeId.ironAxe => '$_forest.upgrade.ironAxe.effect'.tr(namedArgs: {'percent': '$percent'}),
    UpgradeId.ironPickaxe => '$_forest.upgrade.ironPickaxe.effect'.tr(namedArgs: {'percent': '$percent'}),
  };
  static String get forestUpgradeOwned => '$_forest.upgrade.owned'.tr();
  static String get forestUpgradeNeedsWorkshop => '$_forest.upgrade.needsWorkshop'.tr();
  static String forestMessageUpgradePurchased({required String name}) =>
      '$_forest.message.upgradePurchased'.tr(namedArgs: {'name': name});
  static String get forestMessageUpgradeOwned => '$_forest.message.upgradeOwned'.tr();
  static const String _arena = 'arena';
  static String get arenaTitle => '$_arena.title'.tr();
  static String arenaHeroPower({required int power}) => '$_arena.heroPower'.tr(namedArgs: {'power': '$power'});
  static String arenaPower({required int power}) => '$_arena.power'.tr(namedArgs: {'power': '$power'});
  static String arenaReward({required Map<Resource, int> amounts}) => '$_arena.reward'.tr(
    namedArgs: {
      'amounts': [
        for (final resource in Resource.values)
          if (amounts[resource] case final amount? when amount > 0) forestAmount(resource: resource, amount: amount),
      ].join(', '),
    },
  );
  static String get arenaCleared => '$_arena.cleared'.tr();
  static String get arenaLocked => '$_arena.locked'.tr();
  static String get arenaFight => '$_arena.fight'.tr();
  static String get arenaBack => '$_arena.back'.tr();
  static String get arenaRetry => '$_arena.retry'.tr();
  static String get arenaVictory => '$_arena.victory'.tr();
  static String get arenaChampion => '$_arena.champion'.tr();
  static String get arenaDefeat => '$_arena.defeat'.tr();
  static String arenaDamage({required int amount}) => '$_arena.damage'.tr(namedArgs: {'amount': '$amount'});
  static String arenaHeal({required int amount}) => '$_arena.heal'.tr(namedArgs: {'amount': '$amount'});
  static String arenaSkillUsed({required SkillId id}) =>
      '$_arena.skillUsed'.tr(namedArgs: {'name': forestSkillName(id: id)});
  static String arenaEnemyCount({required int count, required String name}) =>
      '$_arena.enemyCount'.tr(namedArgs: {'count': '$count', 'name': name});
  static String arenaLevel({required ArenaLevelId id}) => switch (id) {
    ArenaLevelId.banditRookie => '$_arena.level.banditRookie'.tr(),
    ArenaLevelId.banditVeteran => '$_arena.level.banditVeteran'.tr(),
    ArenaLevelId.banditTrio => '$_arena.level.banditTrio'.tr(),
    ArenaLevelId.barbarian => '$_arena.level.barbarian'.tr(),
    ArenaLevelId.barbarianPair => '$_arena.level.barbarianPair'.tr(),
    ArenaLevelId.barbarianChief => '$_arena.level.barbarianChief'.tr(),
    ArenaLevelId.wolf => '$_arena.level.wolf'.tr(),
    ArenaLevelId.wolfPair => '$_arena.level.wolfPair'.tr(),
    ArenaLevelId.bear => '$_arena.level.bear'.tr(),
    ArenaLevelId.wolfPack => '$_arena.level.wolfPack'.tr(),
  };
  static String arenaEnemy({required EnemyKind kind}) => switch (kind) {
    EnemyKind.bandit => '$_arena.enemy.bandit'.tr(),
    EnemyKind.barbarian => '$_arena.enemy.barbarian'.tr(),
    EnemyKind.barbarianChief => '$_arena.enemy.barbarianChief'.tr(),
    EnemyKind.wolf => '$_arena.enemy.wolf'.tr(),
    EnemyKind.bear => '$_arena.enemy.bear'.tr(),
    EnemyKind.banditVeteran => '$_arena.enemy.banditVeteran'.tr(),
  };
  static String arenaAdvice({required FightAdvice advice}) => switch (advice) {
    FightAdvice.almostThere => '$_arena.advice.almostThere'.tr(),
    FightAdvice.needAttack => '$_arena.advice.needAttack'.tr(),
    FightAdvice.needDefense => '$_arena.advice.needDefense'.tr(),
  };
  static String get arenaMessageLocked => '$_arena.message.locked'.tr();
  static String get arenaAccessibilityStage => '$_arena.accessibility.stage'.tr();
}
