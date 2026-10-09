import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/quest_line.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/quests/quest_log.dart';
import 'package:rpg/layers/domain/rules/blueprints.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';
import 'package:rpg/layers/domain/world/extensions/player_rules.dart';

import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/game/quest_progress_entity_mock.dart';
import '../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../mocks/domain/entities/player/inventory_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenGameStartsThenEveryQuestIsPendingAndEachLineHasItsFirstQuestCurrent', () {
    // given
    final world = WorldMock.make();

    // when
    final status = QuestLog().status(world);

    // then
    expect(status.where((quest) => quest.line == QuestLine.village), const [
      QuestProgressEntityMock.pickUpAxePending,
      QuestProgressEntityMock.gatherWoodPending,
      QuestProgressEntityMock.buildHousePending,
    ]);
    expect(status.where((quest) => quest.line == QuestLine.hero).first, QuestProgressEntityMock.buildForgeCurrent);
    expect(status.where((quest) => quest.isCurrent), hasLength(2));
  });

  test('testWhenTheHeroHasBecomeChampionThenItsQuestsAreFulfilledAndTheArenaOneCountsLevels', () {
    // given
    final world = WorldMock.withHero(HeroEntityMock.champion);
    final questLog = QuestLog();

    // when
    final completed = questLog.update(world).map((event) => event.questId);
    final halfArena = questLog.status(world).firstWhere((quest) => quest.id == QuestId.clearHalfArena);

    // then
    expect(completed, [QuestId.winFirstFight, QuestId.buyFirstWeapon, QuestId.learnASkill, QuestId.becomeChampion]);
    expect((halfArena.progress, halfArena.target, halfArena.isCurrent), (2, 5, false));
  });

  test('testWhenQuestIsFulfilledThenItIsReportedOnlyOnce', () {
    // given
    final world = WorldMock.make();
    final questLog = QuestLog();
    world.updatePlayer((player) => player.withInventory(player.inventory.addTool(ToolKind.axe)));

    // when
    final first = questLog.update(world);
    final second = questLog.update(world);

    // then
    expect(first, const [GameEventEntityMock.pickUpAxeCompleted]);
    expect(second, isEmpty);
  });

  test('testWhenWoodIsSpentAfterCompletingThenWoodQuestStaysCompleted', () {
    // given
    final world = WorldMock.make();
    final questLog = QuestLog();
    world.updatePlayer((player) => player.withInventory(player.inventory.add(Resource.wood, 16)));
    questLog.update(world);

    // when
    world.updatePlayer((player) => player.withInventory(player.inventory.spend(InventoryEntityMock.sixteenWood)!));

    // then
    final woodQuest = questLog.status(world).firstWhere((quest) => quest.id == QuestId.gatherWood);
    expect(woodQuest, QuestProgressEntityMock.gatherWoodCompleted);
  });

  test('testWhenProgressExceedsTargetThenItIsCapped', () {
    // given
    final world = WorldMock.make();
    world.updatePlayer((player) => player.withInventory(player.inventory.add(Resource.wood, 40)));

    // when
    final woodQuest = QuestLog().status(world).firstWhere((quest) => quest.id == QuestId.gatherWood);

    // then
    expect(woodQuest.progress, 15);
  });

  test('testWhenHouseIsOnlyPlacedThenBuildQuestIsNotCompleted', () {
    // given
    final world = WorldMock.make();
    final questLog = QuestLog();
    world.updatePlayer((player) => player.withInventory(player.inventory.add(Resource.wood, 15)));
    questLog.update(world);
    world.orderConstruction(Blueprints.house, const PositionEntity(x: 300, y: 100));

    // when
    final whilePlaced = questLog.update(world);
    world.advanceFor(10000);
    final whenFinished = questLog.update(world);

    // then
    expect(whilePlaced, isEmpty);
    expect(whenFinished, const [GameEventEntityMock.buildHouseCompleted]);
  });
}
