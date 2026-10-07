import 'package:easy_localization/easy_localization.dart';

import '../../config/constants/enum/blueprint_id.dart';
import '../../config/constants/enum/forest/hero_panel_section.dart';
import '../../config/constants/enum/gear_id.dart';
import '../../config/constants/enum/gear_slot.dart';
import '../../config/constants/enum/quest_id.dart';
import '../../config/constants/enum/resource.dart';
import '../../config/constants/enum/tool_kind.dart';

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

  static const String _forest = 'forest';
  static String forestResource({required Resource resource}) => switch (resource) {
    Resource.wood => '$_forest.resource.wood'.tr(),
    Resource.gold => '$_forest.resource.gold'.tr(),
  };
  static String forestTool({required ToolKind tool}) => switch (tool) {
    ToolKind.axe => '$_forest.tool.axe'.tr(),
  };
  static String get forestBuild => '$_forest.hud.build'.tr();
  static String get forestQuests => '$_forest.hud.quests'.tr();
  static String get forestQuestDone => '$_forest.hud.questDone'.tr();
  static String forestAmount({required Resource resource, required int amount}) => switch (resource) {
    Resource.wood => '$_forest.amount.wood'.tr(namedArgs: {'amount': '$amount'}),
    Resource.gold => '$_forest.amount.gold'.tr(namedArgs: {'amount': '$amount'}),
  };
  static String forestMissing({required String amounts}) => '$_forest.hud.missing'.tr(namedArgs: {'amounts': amounts});
  static String forestBlueprint({required BlueprintId id}) => switch (id) {
    BlueprintId.house => '$_forest.blueprint.house'.tr(),
    BlueprintId.forge => '$_forest.blueprint.forge'.tr(),
    BlueprintId.armory => '$_forest.blueprint.armory'.tr(),
  };
  static String forestQuestTitle({required QuestId id}) => switch (id) {
    QuestId.pickUpAxe => '$_forest.quest.pickUpAxe'.tr(),
    QuestId.gatherWood => '$_forest.quest.gatherWood'.tr(),
    QuestId.buildHouse => '$_forest.quest.buildHouse'.tr(),
  };
  static String get forestMessageWelcome => '$_forest.message.welcome'.tr();
  static String get forestMessageNeedAxe => '$_forest.message.needAxe'.tr();
  static String get forestMessageBlockedPath => '$_forest.message.blockedPath'.tr();
  static String get forestMessagePickedUpAxe => '$_forest.message.pickedUpAxe'.tr();
  static String get forestMessageBlockedSite => '$_forest.message.blockedSite'.tr();
  static String get forestMessageNotEnoughResources => '$_forest.message.notEnoughResources'.tr();
  static String get forestMessageBuildingStarted => '$_forest.message.buildingStarted'.tr();
  static String get forestMessageAllQuestsCompleted => '$_forest.message.allQuestsCompleted'.tr();
  static String forestMessageWoodGained({required int wood}) =>
      '$_forest.message.woodGained'.tr(namedArgs: {'wood': '$wood'});
  static String forestMessagePlacing({required String name}) =>
      '$_forest.message.placing'.tr(namedArgs: {'name': name});
  static String forestMessageBuildingCompleted({required String name}) =>
      '$_forest.message.buildingCompleted'.tr(namedArgs: {'name': name});
  static String forestMessageQuestCompleted({required String title}) =>
      '$_forest.message.questCompleted'.tr(namedArgs: {'title': title});
  static String get forestPlacementConfirm => '$_forest.placement.confirm'.tr();
  static String get forestPlacementCancel => '$_forest.placement.cancel'.tr();
  static String get forestAccessibilityGameWorld => '$_forest.accessibility.gameWorld'.tr();
  static String get forestRetry => '$_forest.retry'.tr();
  static String get forestHero => '$_forest.hero.title'.tr();
  static String get forestHeroPower => '$_forest.hero.power'.tr();
  static String get forestHeroAttack => '$_forest.hero.attack'.tr();
  static String get forestHeroDefense => '$_forest.hero.defense'.tr();
  static String get forestHeroHealth => '$_forest.hero.health'.tr();
  static String forestHeroWeaponStats({required int attack}) =>
      '$_forest.hero.weaponStats'.tr(namedArgs: {'attack': '$attack'});
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
}
