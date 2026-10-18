import 'package:flutter_test/flutter_test.dart';
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
    final inventory = SaveScenarioMock.player.inventory;

    // when
    final dbo = sut.toDBO(inventory);

    // then
    expect(dbo, SaveInventoryDBOMock.player);
  });

  test('testWhenMappingDbosToInventoriesThenEveryResourceToolAndLevelComesBack', () {
    // given
    const dbo = SaveInventoryDBOMock.player;

    // when
    final inventory = sut.toEntity(dbo, owner: 'player');

    // then
    expect(inventory, SaveScenarioMock.player.inventory);
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
