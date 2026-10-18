import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_inventory_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_inventory_mapper_dbo.dart';

import '../../../../../mocks/data/datasources/save/save_inventory_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/player/inventory_entity_mock.dart';
import '../../../../../mocks/domain/game/save_scenario_mock.dart';

void main() {
  late SaveInventoryMapperDBO sut;

  setUp(() {
    sut = SaveInventoryMapperDBO();
  });

  test('testWhenMappingInventoriesToDboThenResourcesAndToolsKeepTheirNames', () {
    // given
    final inventories = [SaveScenarioMock.player.inventory, SaveScenarioMock.stock];

    // when
    final dbos = inventories.map(sut.toDBO).toList();

    // then
    expect(dbos, [SaveInventoryDBOMock.player, SaveInventoryDBOMock.stock]);
  });

  test('testWhenMappingDbosToInventoriesThenEveryResourceToolAndLevelComesBack', () {
    // given
    const dbos = [SaveInventoryDBOMock.player, SaveInventoryDBOMock.stock];

    // when
    final inventories = [for (final dbo in dbos) sut.toEntity(dbo, owner: 'player')];

    // then
    expect(inventories, [SaveScenarioMock.player.inventory, SaveScenarioMock.stock]);
  });

  test('testWhenThereIsNoDboThenTheInventoryIsEmpty', () {
    // given
    const SaveInventoryDBO? dbo = null;

    // when
    final inventory = sut.toEntity(dbo, owner: 'stock');

    // then
    expect(inventory, InventoryEntityMock.mock);
  });

  test('testWhenTheDboHasNoFieldsThenTheInventoryIsEmpty', () {
    // given
    const dbo = SaveInventoryDBOMock.empty;

    // when
    final inventory = sut.toEntity(dbo, owner: 'stock');

    // then
    expect(inventory, InventoryEntityMock.mock);
  });

  test('testWhenAResourceIsZeroThenItDoesNotAppearInTheInventory', () {
    // given
    const dbo = SaveInventoryDBOMock.withZeroResource;

    // when
    final inventory = sut.toEntity(dbo, owner: 'stock');

    // then
    expect(inventory.resources, {Resource.stone: 3});
    expect(inventory.resources.containsKey(Resource.wood), isFalse);
  });

  test('testWhenAResourceIsUnknownThenItThrowsNamingTheOwner', () {
    // given
    const dbo = SaveInventoryDBOMock.withUnknownResource;

    // when
    void map() => sut.toEntity(dbo, owner: 'stock');

    // then
    expect(map, throwsInvalidSave('stock: unknown resource "diamond"'));
  });

  test('testWhenAnAmountIsNegativeThenItThrows', () {
    // given
    const dbo = SaveInventoryDBOMock.withNegativeResource;

    // when
    void map() => sut.toEntity(dbo, owner: 'player');

    // then
    expect(map, throwsInvalidSave('player: -1 wood'));
  });

  test('testWhenAToolIsUnknownThenItThrows', () {
    // given
    const dbo = SaveInventoryDBOMock.withUnknownTool;

    // when
    void map() => sut.toEntity(dbo, owner: 'player');

    // then
    expect(map, throwsInvalidSave('player: unknown tool "hammer"'));
  });

  test('testWhenAToolLevelBelongsToAnUnknownToolThenItThrows', () {
    // given
    const dbo = SaveInventoryDBOMock.withUnknownToolLevel;

    // when
    void map() => sut.toEntity(dbo, owner: 'player');

    // then
    expect(map, throwsInvalidSave('player: unknown tool "hammer"'));
  });

  test('testWhenAToolLevelIsBelowOneThenItThrows', () {
    // given
    const dbo = SaveInventoryDBOMock.withToolLevelZero;

    // when
    void map() => sut.toEntity(dbo, owner: 'player');

    // then
    expect(map, throwsInvalidSave('player: axe level 0'));
  });

  test('testWhenAToolLevelIsBeyondTheLastUpgradeThenItIsClippedToTheMaximum', () {
    // given
    const dbo = SaveInventoryDBOMock.withToolLevelBeyondTheMaximum;

    // when
    final inventory = sut.toEntity(dbo, owner: 'player');

    // then
    expect(inventory.toolLevels, {ToolKind.axe: 2, ToolKind.pickaxe: 2});
    expect(inventory.tools, {ToolKind.axe, ToolKind.pickaxe});
  });
}
