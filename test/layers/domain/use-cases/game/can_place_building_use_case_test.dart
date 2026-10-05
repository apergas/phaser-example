import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/use-cases/game/can_place_building_use_case.dart';

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

  test('testWhenCheckingABlockedSiteThenCannotPlace', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.treeOnBuildingSite()));

    // when
    final onTree = sut(blueprint: BlueprintId.house, x: 410, y: 400);
    final onGrass = sut(blueprint: BlueprintId.house, x: 600, y: 600);

    // then
    expect(onTree, isFalse);
    expect(onGrass, isTrue);
  });
}
