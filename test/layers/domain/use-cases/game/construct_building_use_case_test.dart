import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/domain/use-cases/game/construct_building_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/entities/game/construction_result_entity_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late ConstructBuildingUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = ConstructBuildingUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenConstructingWithoutEnoughResourcesThenConstructionIsRejected', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWood()));

    // when
    final result = sut(blueprint: BlueprintId.house, x: 400, y: 400);

    // then
    expect(result, ConstructionResultEntityMock.notEnoughResources);
  });
}
