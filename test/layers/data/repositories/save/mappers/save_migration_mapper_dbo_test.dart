import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_migration_mapper_dbo.dart';

import '../../../../../mocks/data/datasources/save/save_dbo_mock.dart';
import '../../../../../mocks/data/datasources/save/save_player_dbo_mock.dart';
import '../../../../../mocks/data/datasources/save/save_stock_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';

void main() {
  late SaveMigrationMapperDBO sut;

  setUp(() {
    sut = SaveMigrationMapperDBO();
  });

  test('testWhenAVersionThreeSaveIsMigratedThenItIsUnchanged', () {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current, same(dbo));
  });

  test('testWhenAVersionOneSaveIsMigratedThenItBecomesTheVersionThreeGame', () {
    // given
    final dbo = SaveDBOMock.versionOne;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current, SaveDBOMock.versionOneMigrated);
  });

  test('testWhenAVersionTwoSaveIsMigratedThenItBecomesTheVersionThreeGame', () {
    // given
    final dbo = SaveDBOMock.versionTwo;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current, SaveDBOMock.everything);
  });

  test('testWhenAVersionTwoSaveIsMigratedThenTheCampIsRemoved', () {
    // given
    final dbo = SaveDBOMock.versionTwo;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current.buildings, SaveDBOMock.everything.buildings);
  });

  test('testWhenAVersionTwoSaveIsMigratedThenThePickaxeJoinsTheToolsAndTheLevelsAreKept', () {
    // given
    final dbo = SaveDBOMock.versionTwo;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current.player, SavePlayerDBOMock.mock);
    expect(current.version, 3);
  });

  test('testWhenAVersionTwoPlayerAlreadyHasThePickaxeThenItIsNotAddedTwice', () {
    // given
    final dbo = SaveDBOMock.versionTwoWithThePickaxe;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current.player!.inventory!.tools, ['axe', 'pickaxe']);
  });

  test('testWhenAVersionTwoSaveHasNoInventoryThenThePlayerGetsThePickaxe', () {
    // given
    final dbo = SaveDBOMock.versionTwoWithoutInventory;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current, SaveDBOMock.versionTwoWithoutInventoryMigrated);
  });

  test('testWhenAVersionOneSaveIsMigratedThenTheCarriedResourcesJoinTheStock', () {
    // given
    final dbo = SaveDBOMock.versionOne;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current.stock, SaveStockDBOMock.withTheVersionOneLoad);
    expect(current.player!.inventory!.resources, isNull);
  });

  test('testWhenAVersionOneSaveHasNoStockThenTheCarriedResourcesBecomeIt', () {
    // given
    final dbo = SaveDBOMock.versionOneWithoutStock;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current.stock, SaveStockDBOMock.onlyTheVersionOneLoad);
  });

  test('testWhenAVersionOneSaveIsMigratedThenCampsStorehousesAndQuarriesAreRemoved', () {
    // given
    final dbo = SaveDBOMock.versionOne;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current.buildings, SaveDBOMock.everything.buildings);
  });

  test('testWhenAVersionOneSaveIsMigratedThenTheQuarryQuestIsDropped', () {
    // given
    final dbo = SaveDBOMock.versionOne;

    // when
    final current = sut.toCurrent(dbo);

    // then
    expect(current.completedQuests, SaveDBOMock.everything.completedQuests);
  });

  test('testWhenACarriedAmountIsNegativeThenItThrows', () {
    // given
    final dbo = SaveDBOMock.versionOneWithNegativeCarry;

    // when
    void migrate() => sut.toCurrent(dbo);

    // then
    expect(migrate, throwsInvalidSave('player: -1 wood'));
  });

  test('testWhenTheVersionIsUnknownOrMissingThenItThrows', () {
    // given
    final dbos = [SaveDBOMock.otherVersion, SaveDBOMock.withoutVersion];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toCurrent(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('unknown version 4'));
    expect(attempts[1], throwsInvalidSave('unknown version null'));
  });
}
