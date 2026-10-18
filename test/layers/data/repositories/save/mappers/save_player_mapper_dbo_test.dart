import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_inventory_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_player_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';
import 'package:farming/layers/data/datasources/save/local/dbo/save_player_dbo.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/rules/rules.dart';

import '../../../../../mocks/data/datasources/save/save_player_dbo_mock.dart';
import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';
import '../../../../../mocks/domain/entities/player/inventory_entity_mock.dart';
import '../../../../../mocks/domain/game/save_scenario_mock.dart';

void main() {
  late SavePlayerMapperDBO sut;

  setUp(() {
    sut = SavePlayerMapperDBO(positionMapperDBO: SavePositionMapperDBO(), inventoryMapperDBO: SaveInventoryMapperDBO());
  });

  test('testWhenMappingAPlayerToDboThenItKeepsThePositionAndTheInventory', () {
    // given
    const player = SaveScenarioMock.player;

    // when
    final dbo = sut.toDBO(player);

    // then
    expect(dbo, SavePlayerDBOMock.mock);
  });

  test('testWhenMappingADboToAPlayerThenSpeedAndRadiusComeFromTheRules', () {
    // given
    const dbo = SavePlayerDBOMock.mock;

    // when
    final player = sut.toEntity(dbo);

    // then
    expect(player, SaveScenarioMock.player);
    expect(player.speed, Rules.playerSpeed);
    expect(player.radius, Rules.playerRadius);
  });

  test('testWhenThereIsNoPlayerThenItThrows', () {
    // given
    const SavePlayerDBO? dbo = null;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('missing player'));
  });

  test('testWhenThePlayerHasNoInventoryThenItCarriesNothing', () {
    // given
    const dbo = SavePlayerDBOMock.withoutInventory;

    // when
    final player = sut.toEntity(dbo);

    // then
    expect(player.inventory, InventoryEntityMock.mock);
    expect(player.position, const PositionEntity(x: 420, y: 380));
  });

  test('testWhenTheInventoryIsInvalidThenItThrowsNamingThePlayer', () {
    // given
    const dbo = SavePlayerDBOMock.withBadInventory;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsInvalidSave('player: unknown tool "hammer"'));
  });

  test('testWhenACoordinateIsMissingThenItThrows', () {
    // given
    const dbos = [SavePlayerDBOMock.withoutX, SavePlayerDBOMock.withoutY];

    // when
    final attempts = [for (final dbo in dbos) () => sut.toEntity(dbo)];

    // then
    expect(attempts[0], throwsInvalidSave('player without x'));
    expect(attempts[1], throwsInvalidSave('player without y'));
  });
}
