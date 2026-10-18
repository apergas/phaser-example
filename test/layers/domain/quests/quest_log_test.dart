import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/quest_id.dart';
import 'package:farming/core/config/constants/enum/quest_line.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/quests/quest_log.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';

import '../../../mocks/domain/entities/stock/stock_entity_mock.dart';
import '../../../mocks/domain/entities/game/game_event_entity_mock.dart';
import '../../../mocks/domain/entities/game/quest_progress_entity_mock.dart';
import '../../../mocks/domain/entities/game/stats_entity_mock.dart';
import '../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../mocks/domain/world/funds_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenGameStartsThenEveryQuestIsPendingAndEachLineHasItsFirstQuestCurrent', () {
    // given
    final world = WorldMock.make();

    // when
    final status = QuestLog().status(world);

    // then
    final village = status.where((quest) => quest.line == QuestLine.village).toList();
    expect(status, hasLength(19));
    expect(village, hasLength(11));
    expect(village.take(2), const [
      QuestProgressEntityMock.gatherWoodCurrent,
      QuestProgressEntityMock.buildHousePending,
    ]);
    expect(status.where((quest) => quest.line == QuestLine.hero).first, QuestProgressEntityMock.buildForgeCurrent);
    expect(status.where((quest) => quest.isCurrent), hasLength(2));
    expect(status.where((quest) => quest.isCompleted), isEmpty);
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
    final world = WorldMock.withStock(FundsMock.fifteenWood);
    final questLog = QuestLog();

    // when
    final first = questLog.update(world);
    final second = questLog.update(world);

    // then
    expect(first, const [GameEventEntityMock.gatherWoodCompleted]);
    expect(second, isEmpty);
  });

  test('testWhenLaterVillageQuestsAreDoneFirstThenTheyCompleteOutOfOrderAndTheCurrentOneStays', () {
    // given
    final world = WorldMock.restored(stats: StatsEntityMock.afterTenTrees);
    final questLog = QuestLog();

    // when
    final completed = questLog.update(world).map((event) => event.questId);
    final current = questLog.status(world).where((quest) => quest.isCurrent).map((quest) => quest.id);

    // then
    expect(completed, [QuestId.fellTenTrees, QuestId.fellAnOak]);
    expect(current, [QuestId.gatherWood, QuestId.buildForge]);
  });

  test('testWhenWoodIsSpentAfterCompletingThenWoodQuestsStayCompleted', () {
    // given
    final world = WorldMock.withStock(StockEntityMock.fortyWood);
    final questLog = QuestLog();
    final completed = questLog.update(world).map((event) => event.questId).toList();

    // when
    world.spend(StockEntityMock.fortyWood);

    // then
    final status = questLog.status(world);
    expect(completed, [QuestId.gatherWood, QuestId.gatherFortyWood]);
    expect(status.firstWhere((quest) => quest.id == QuestId.gatherWood), QuestProgressEntityMock.gatherWoodCompleted);
    expect(status.firstWhere((quest) => quest.id == QuestId.gatherFortyWood).isCompleted, isTrue);
  });

  test('testWhenProgressExceedsTargetThenItIsCapped', () {
    // given
    final world = WorldMock.withStock(StockEntityMock.fortyWood);

    // when
    final woodQuest = QuestLog().status(world).firstWhere((quest) => quest.id == QuestId.gatherWood);

    // then
    expect(woodQuest.progress, 15);
  });

  test('testWhenHouseIsOnlyPlacedThenBuildQuestIsNotCompleted', () {
    // given
    final world = WorldMock.withStock(FundsMock.fifteenWood);
    final questLog = QuestLog();
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

  test('testWhenCreatedWithCompletedQuestsThenTheyStayCompletedAndAreNotAnnouncedAgain', () {
    // given
    final world = WorldMock.make();
    final questLog = QuestLog(completed: {QuestId.gatherWood, QuestId.buildForge});

    // when
    final announced = questLog.update(world);
    final status = questLog.status(world);

    // then
    expect(announced, isEmpty);
    expect(questLog.completed, {QuestId.gatherWood, QuestId.buildForge});
    expect(status.firstWhere((quest) => quest.id == QuestId.gatherWood), QuestProgressEntityMock.gatherWoodCompleted);
    expect(status.where((quest) => quest.isCurrent).map((quest) => quest.id), [
      QuestId.buildHouse,
      QuestId.winFirstFight,
    ]);
  });

  test('testWhenQuestsAreCompletedThenTheCompletedSetGrowsAndCannotBeChangedFromOutside', () {
    // given
    final questLog = QuestLog();
    questLog.update(WorldMock.withStock(FundsMock.fifteenWood));

    // when
    final completed = questLog.completed;

    // then
    expect(completed, {QuestId.gatherWood});
    expect(() => completed.add(QuestId.buildHouse), throwsUnsupportedError);
  });
}
