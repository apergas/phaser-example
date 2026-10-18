import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';
import 'package:farming/core/config/constants/enum/upgrade_result.dart';
import 'package:farming/layers/domain/use-cases/game/buy_upgrade_use_case.dart';
import 'package:farming/layers/domain/world/extensions/inventory_rules.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/entities/player/inventory_entity_mock.dart';
import '../../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../../mocks/domain/game/upgrade_scenario_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late BuyUpgradeUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = BuyUpgradeUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenTheAxeIsAlreadyUpgradedThenItIsOwnedEvenWithoutAWorkshop', () {
    // given
    playing(WorldMock.restored(player: PlayerEntityMock.withIronAxe));

    // when
    final result = sut(id: UpgradeId.ironAxe);

    // then
    expect(result, UpgradeResult.alreadyOwned);
  });

  test('testWhenThereIsNoFinishedWorkshopThenItIsReportedBeforeTheFunds', () {
    // given
    final withoutWorkshop = WorldMock.restored(player: PlayerEntityMock.withAxe);
    final withSite = WorldMock.restored(
      player: PlayerEntityMock.withAxe,
      buildings: [UpgradeScenarioMock.workshopSite],
    );

    // when
    playing(withoutWorkshop);
    final noWorkshop = sut(id: UpgradeId.ironAxe);
    playing(withSite);
    final unfinished = sut(id: UpgradeId.ironAxe);

    // then
    expect((noWorkshop, unfinished), (UpgradeResult.noWorkshop, UpgradeResult.noWorkshop));
  });

  test('testWhenTheStockIsShortThenNothingIsPaidAndTheLevelStays', () {
    // given
    final world = playing(UpgradeScenarioMock.withWorkshop(stock: UpgradeScenarioMock.fiveStoneShortOfTheIronAxe));

    // when
    final result = sut(id: UpgradeId.ironAxe);

    // then
    expect(result, UpgradeResult.notEnoughResources);
    expect(world.stock, InventoryEntityMock.make(wood: 15, stone: 10));
    expect(world.player.inventory.toolLevel(ToolKind.axe), 1);
  });

  test('testWhenTheWoodAndStoneAreOnlyCarriedThenTheUpgradeCannotBePaid', () {
    // given
    final world = playing(
      UpgradeScenarioMock.withWorkshop(player: UpgradeScenarioMock.carryingTheIronAxePrice),
    );

    // when
    final result = sut(id: UpgradeId.ironAxe);

    // then
    expect(result, UpgradeResult.notEnoughResources);
    expect(world.player.inventory.load, 10);
  });

  test('testWhenEverythingIsInPlaceThenItIsPaidFromTheStockAndTheToolGoesUpALevel', () {
    // given
    final world = playing(
      UpgradeScenarioMock.withWorkshop(
        stock: UpgradeScenarioMock.ironAxePrice,
        player: UpgradeScenarioMock.carryingTheIronAxePrice,
      ),
    );

    // when
    final result = sut(id: UpgradeId.ironAxe);

    // then
    expect(result, UpgradeResult.ok);
    expect(world.player.inventory.toolLevel(ToolKind.axe), 2);
    expect(world.stock, InventoryEntityMock.mock);
    expect(world.player.inventory.load, 10);
  });

  test('testWhenThePickaxeIsNotOwnedThenItCanStillBeUpgraded', () {
    // given
    final world = playing(UpgradeScenarioMock.withWorkshop(stock: UpgradeScenarioMock.ironPickaxePrice));

    // when
    final result = sut(id: UpgradeId.ironPickaxe);

    // then
    expect(result, UpgradeResult.ok);
    expect(world.player.inventory.hasTool(ToolKind.pickaxe), isFalse);
    expect(world.player.inventory.toolLevel(ToolKind.pickaxe), 2);
  });
}
