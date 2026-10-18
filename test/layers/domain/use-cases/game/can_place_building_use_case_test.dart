import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/construction_rejection.dart';
import 'package:farming/layers/domain/use-cases/game/can_place_building_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late CanPlaceBuildingUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = CanPlaceBuildingUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenCheckingABlockedSiteThenItIsBlockedAndGrassIsFine', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.treeOnBuildingSite()));

    // when
    final onTree = sut(blueprint: BlueprintId.house, x: 410, y: 400);
    final onGrass = sut(blueprint: BlueprintId.house, x: 600, y: 600);

    // then
    expect(onTree, ConstructionRejection.blocked);
    expect(onGrass, isNull);
  });

  test('testWhenCheckingAQuarryThenItMustBeNearARock', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.besideARock()));

    // when
    final far = sut(blueprint: BlueprintId.quarry, x: 300, y: 400);
    final near = sut(blueprint: BlueprintId.quarry, x: 300, y: 200);

    // then
    expect(far, ConstructionRejection.needsNearbyRock);
    expect(near, isNull);
  });

  test('testWhenCheckingTheCampThenItCannotBePlaced', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.besideARock()));

    // when
    final camp = sut(blueprint: BlueprintId.camp, x: 600, y: 600);

    // then
    expect(camp, ConstructionRejection.blocked);
  });
}
