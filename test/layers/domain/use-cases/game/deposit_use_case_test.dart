import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/core/config/constants/enum/deposit_result.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/use-cases/game/deposit_use_case.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/entities/building/building_entity_mock.dart';
import '../../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late DepositUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = DepositUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenDepositingALoadAtTheCampThenThePlayerGoesToUnload', () {
    // given
    final world = playing(
      WorldMock.restored(player: PlayerEntityMock.carryingMixedLoad, buildings: [BuildingEntityMock.camp]),
    );

    // when
    final result = sut(buildingId: 'camp');

    // then
    expect(result, DepositResult.ok);
    expect(world.player.activity, isA<WalkingActivityEntity>());
  });

  test('testWhenThereIsNothingToDepositThenTheLoadIsEmpty', () {
    // given
    playing(WorldMock.restored(player: PlayerEntityMock.withAxe, buildings: [BuildingEntityMock.camp]));

    // when
    final result = sut(buildingId: 'camp');

    // then
    expect(result, DepositResult.emptyLoad);
  });

  test('testWhenTheBuildingIsNotADropOffOrUnknownThenItIsReported', () {
    // given
    playing(
      WorldMock.restored(player: PlayerEntityMock.carryingMixedLoad, buildings: [BuildingEntityMock.finishedHouse]),
    );

    // when
    final results = [sut(buildingId: 'house'), sut(buildingId: 'building-99')];

    // then
    expect(results, [DepositResult.notADropOff, DepositResult.unknownBuilding]);
  });
}
