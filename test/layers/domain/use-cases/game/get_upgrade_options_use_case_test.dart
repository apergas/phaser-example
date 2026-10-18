import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/layers/domain/use-cases/game/get_upgrade_options_use_case.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../../mocks/domain/entities/upgrade/upgrade_option_entity_mock.dart';
import '../../../../mocks/domain/game/upgrade_scenario_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetUpgradeOptionsUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetUpgradeOptionsUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenThereIsNoWorkshopThenEveryUpgradeNeedsItAndSaysItsFullPrice', () {
    // given
    playing(WorldMock.restored(player: PlayerEntityMock.withAxe));

    // when
    final options = sut();

    // then
    expect(options, [
      UpgradeOptionEntityMock.ironAxeWithoutWorkshop,
      UpgradeOptionEntityMock.ironPickaxeWithoutWorkshop,
    ]);
  });

  test('testWhenTheStockIsShortThenTheUpgradesAreUnaffordableWithWhatIsMissing', () {
    // given
    playing(UpgradeScenarioMock.withWorkshop(stock: UpgradeScenarioMock.fiveStoneShortOfTheIronAxe));

    // when
    final options = sut();

    // then
    expect(options, [UpgradeOptionEntityMock.ironAxeFiveStoneShort, UpgradeOptionEntityMock.ironPickaxeTenStoneShort]);
  });

  test('testWhenTheStockPaysAndTheAxeIsOwnedThenTheAxeIsOwnedWithoutMissingAndThePickaxeAvailable', () {
    // given
    playing(
      UpgradeScenarioMock.withWorkshop(
        stock: UpgradeScenarioMock.ironPickaxePrice,
        player: PlayerEntityMock.withIronAxe,
      ),
    );

    // when
    final options = sut();

    // then
    expect(options, [UpgradeOptionEntityMock.ironAxeOwned, UpgradeOptionEntityMock.ironPickaxeAvailable]);
  });

  test('testWhenTheStockPaysForTheAxeThenTheAxeIsAvailable', () {
    // given
    playing(UpgradeScenarioMock.withWorkshop(stock: UpgradeScenarioMock.ironAxePrice));

    // when
    final options = sut();

    // then
    expect(options.first, UpgradeOptionEntityMock.ironAxeAvailable);
  });
}
