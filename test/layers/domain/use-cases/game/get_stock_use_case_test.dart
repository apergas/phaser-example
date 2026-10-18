import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/layers/domain/use-cases/game/get_stock_use_case.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/stock/stock_entity_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetStockUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetStockUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenReadingTheStockThenItIsTheStoredResourcesAndNotTheCarriedOnes', () {
    // given
    playing(
      WorldMock.restored(
        player: PlayerEntityMock.carryingMixedLoad,
        stock: StockEntityMock.make(wood: 6, stone: 3),
      ),
    );

    // when
    final stock = sut();

    // then
    expect(stock, StockEntityMock.make(wood: 6, stone: 3));
  });

  test('testWhenNothingWasStoredThenTheStockIsEmpty', () {
    // given
    playing(WorldMock.restored(player: PlayerEntityMock.carryingMixedLoad));

    // when
    final stock = sut();

    // then
    expect(stock, StockEntityMock.mock);
  });
}
