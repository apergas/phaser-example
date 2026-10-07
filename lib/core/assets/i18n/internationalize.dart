import 'package:easy_localization/easy_localization.dart';

import '../../config/constants/enum/arena_level_id.dart';
import '../../config/constants/enum/blueprint_id.dart';
import '../../config/constants/enum/enemy_kind.dart';
import '../../config/constants/enum/fight_advice.dart';
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
  static const String _arena = 'arena';
  static String get arenaTitle => '$_arena.title'.tr();
  static String arenaHeroPower({required int power}) => '$_arena.heroPower'.tr(namedArgs: {'power': '$power'});
  static String arenaPower({required int power}) => '$_arena.power'.tr(namedArgs: {'power': '$power'});
  static String arenaReward({required int amount}) => '$_arena.reward'.tr(namedArgs: {'amount': '$amount'});
  static String get arenaCleared => '$_arena.cleared'.tr();
  static String get arenaLocked => '$_arena.locked'.tr();
  static String get arenaFight => '$_arena.fight'.tr();
  static String get arenaBack => '$_arena.back'.tr();
  static String get arenaSkip => '$_arena.skip'.tr();
  static String get arenaRetry => '$_arena.retry'.tr();
  static String get arenaVictory => '$_arena.victory'.tr();
  static String get arenaDefeat => '$_arena.defeat'.tr();
  static String arenaDamage({required int amount}) => '$_arena.damage'.tr(namedArgs: {'amount': '$amount'});
  static String arenaHeal({required int amount}) => '$_arena.heal'.tr(namedArgs: {'amount': '$amount'});
  static String get arenaDodge => '$_arena.dodge'.tr();
  static String arenaEnemyCount({required int count, required String name}) =>
      '$_arena.enemyCount'.tr(namedArgs: {'count': '$count', 'name': name});
  static String arenaLevel({required ArenaLevelId id}) => switch (id) {
    ArenaLevelId.banditRookie => '$_arena.level.banditRookie'.tr(),
    ArenaLevelId.banditVeteran => '$_arena.level.banditVeteran'.tr(),
    ArenaLevelId.banditTrio => '$_arena.level.banditTrio'.tr(),
    ArenaLevelId.barbarian => '$_arena.level.barbarian'.tr(),
    ArenaLevelId.barbarianPair => '$_arena.level.barbarianPair'.tr(),
    ArenaLevelId.barbarianChief => '$_arena.level.barbarianChief'.tr(),
  };
  static String arenaEnemy({required EnemyKind kind}) => switch (kind) {
    EnemyKind.bandit => '$_arena.enemy.bandit'.tr(),
    EnemyKind.barbarian => '$_arena.enemy.barbarian'.tr(),
    EnemyKind.barbarianChief => '$_arena.enemy.barbarianChief'.tr(),
  };
  static String arenaAdvice({required FightAdvice advice}) => switch (advice) {
    FightAdvice.almostThere => '$_arena.advice.almostThere'.tr(),
    FightAdvice.needAttack => '$_arena.advice.needAttack'.tr(),
    FightAdvice.needDefense => '$_arena.advice.needDefense'.tr(),
  };
  static String get arenaMessageLocked => '$_arena.message.locked'.tr();
  static String get arenaAccessibilityStage => '$_arena.accessibility.stage'.tr();
}
