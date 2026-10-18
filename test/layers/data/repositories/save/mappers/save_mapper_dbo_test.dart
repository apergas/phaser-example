import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/quest_id.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_mapper_dbo.dart';

import '../../../../../mocks/domain/entities/stock/stock_entity_mock.dart';
import '../../../../../mocks/data/datasources/save/save_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/data/repositories/save/save_mapper_dbo_factory.dart';
import '../../../../../mocks/data/repositories/save/same_game_matcher.dart';
import '../../../../../mocks/data/repositories/save/save_round_trip_mock.dart';
import '../../../../../mocks/domain/entities/game/stats_entity_mock.dart';
import '../../../../../mocks/domain/entities/hero/hero_entity_mock.dart';
import '../../../../../mocks/domain/game/save_scenario_mock.dart';

void main() {
  late SaveMapperDBO sut;

  setUp(() {
    sut = makeSaveMapperDBO();
  });

  test('testWhenMappingASessionToDboThenItHoldsTheWholeWorldAndTheCompletedQuests', () {
    // given
    final session = SaveScenarioMock.session();

    // when
    final dbo = sut.toDBO(session);

    // then
    expect(dbo, SaveDBOMock.everything);
    expect(dbo.version, SaveDBO.currentVersion);
  });

  test('testWhenSavingThenTheQuestsFollowTheEnumOrderAndTheCountersAreACopy', () {
    // given
    final session = SaveScenarioMock.session();

    // when
    final dbo = sut.toDBO(session);

    // then
    expect(dbo.completedQuests, [QuestId.gatherWood.name, QuestId.buildHouse.name, QuestId.buildForge.name]);
    expect(dbo.idCounters, isNot(same(session.world.idCounters)));
  });

  test('testWhenMappingADboToASessionThenEveryPieceOfTheWorldComesBack', () {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    final session = sut.toEntity(dbo);

    // then
    final expected = SaveRoundTripMock.session();
    expectSameGame(session, expected);
    expect(session.world.trees.map((tree) => (tree.id, tree.hitsTaken)), [('tree-1', 3), ('neighbour', 0)]);
    expect(session.world.buildings.map((building) => (building.id, building.hitsDone)), [
      ('camp', 1),
      ('building-1', 8),
      ('building-3', 4),
    ]);
  });

  test('testWhenRestoringTheScenarioTreesThenTheirStatsComeFromTheRulesAndNotFromTheSave', () {
    // given
    final session = SaveScenarioMock.session();

    // when
    final restored = sut.toEntity(sut.toDBO(session));

    // then
    final original = session.world.trees;
    final back = restored.world.trees;
    expect(back.map((tree) => (tree.id, tree.kind, tree.position, tree.hitsTaken)), [
      for (final tree in original) (tree.id, tree.kind, tree.position, tree.hitsTaken),
    ]);
    expect(back.map((tree) => (tree.trunkRadius, tree.woodYield, tree.hitsToFell)), [(12, 8, 7), (12, 8, 7)]);
  });

  test('testWhenTheGameGoesThroughJsonAndBackThenItIsTheSameGame', () {
    // given
    final session = SaveRoundTripMock.session();

    // when
    final dbo = sut.toDBO(session);
    final json = jsonEncode(dbo.toJson());
    final read = SaveDBO.fromJson(jsonDecode(json) as Map<String, dynamic>);
    final restored = sut.toEntity(read);

    // then
    expect(read, dbo);
    expectSameGame(restored, session);
  });

  test('testWhenTheRestoredWorldSavesAgainThenTheDboIsTheSame', () {
    // given
    final restored = sut.toEntity(SaveDBOMock.everything);

    // when
    final dbo = sut.toDBO(restored);

    // then
    expect(dbo, SaveDBOMock.everything);
  });

  test('testWhenTheOptionalListsAreMissingThenTheWorldIsEmptyOfThem', () {
    // given
    final dbo = SaveDBOMock.withNothingElse;

    // when
    final session = sut.toEntity(dbo);

    // then
    expect(session.world.trees, isEmpty);
    expect(session.world.idCounters, isEmpty);
    expect(session.quests.completed, isEmpty);
  });

  test('testWhenOnlyTheSizeAndThePlayerAreSavedThenTheRestTakesItsDefaults', () {
    // given
    const dbo = SaveDBOMock.onlyWorldSize;

    // when
    final session = sut.toEntity(dbo);

    // then
    expect((session.world.width, session.world.height), (400, 300));
    expect(session.world.hero, HeroEntityMock.mock);
    expect(session.world.stats, StatsEntityMock.empty);
    expect(session.world.stock, StockEntityMock.mock);
    expect(session.world.buildings, isEmpty);
    expect(session.world.stumps, isEmpty);
  });

  test('testWhenTheVersionIsNotTheCurrentOneThenItThrows', () {
    // given
    final dbos = [SaveDBOMock.otherVersion, SaveDBOMock.withoutVersion];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('unknown version 2'));
    expect(attempts[1], throwsInvalidSave('unknown version null'));
  });

  test('testWhenTheWorldWidthIsMissingOrNotPositiveThenItThrows', () {
    // given
    final dbos = [SaveDBOMock.withoutWidth, SaveDBOMock.withZeroWidth];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('world width null'));
    expect(attempts[1], throwsInvalidSave('world width ${0.0}'));
  });

  test('testWhenTheWorldHeightIsMissingOrNotPositiveThenItThrows', () {
    // given
    final dbos = [SaveDBOMock.withoutHeight, SaveDBOMock.withNegativeHeight];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('world height null'));
    expect(attempts[1], throwsInvalidSave('world height ${-5.0}'));
  });

  test('testWhenThePlayerIsMissingThenItThrows', () {
    // given
    final dbo = SaveDBOMock.withoutPlayer;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('missing player'));
  });

  test('testWhenAnIdCounterIsNegativeThenItThrows', () {
    // given
    final dbo = SaveDBOMock.withNegativeCounter;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('id counter building -1'));
  });

  test('testWhenACompletedQuestIsUnknownThenItThrows', () {
    // given
    final dbo = SaveDBOMock.withUnknownQuest;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('unknown quest "saveTheWorld"'));
  });

  test('testWhenAPieceIsOutOfRangeThenItsMapperThrows', () {
    // given
    final dbo = SaveDBOMock.withBadTree;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('tree tree-1: 7 hits taken of 7'));
  });

  test('testWhenTheCountersAreRestoredThenTheNextIdKeepsTheNumbering', () {
    // given
    final dbos = [SaveDBOMock.everything, SaveDBOMock.withOtherCounters];

    // when
    final counters = dbos.map((dbo) => sut.toEntity(dbo).world.idCounters).toList();

    // then
    expect(counters, [
      {'building': 3},
      {'building': 4},
    ]);
  });
}
