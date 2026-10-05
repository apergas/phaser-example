import 'package:easy_localization/easy_localization.dart';

import '../../config/constants/enum/blueprint_id.dart';
import '../../config/constants/enum/quest_id.dart';

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
  static String get forestWood => '$_forest.hud.wood'.tr();
  static String get forestAxe => '$_forest.hud.axe'.tr();
  static String get forestBuild => '$_forest.hud.build'.tr();
  static String get forestQuests => '$_forest.hud.quests'.tr();
  static String get forestQuestDone => '$_forest.hud.questDone'.tr();
  static String forestCost({required int wood}) => '$_forest.hud.cost'.tr(namedArgs: {'wood': '$wood'});
  static String forestMissing({required int wood}) => '$_forest.hud.missing'.tr(namedArgs: {'wood': '$wood'});
  static String forestBlueprint({required BlueprintId id}) => switch (id) {
    BlueprintId.house => '$_forest.blueprint.house'.tr(),
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
  static String get forestMessageNotEnoughWood => '$_forest.message.notEnoughWood'.tr();
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
}
