import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/resume_construction_result.dart';
import 'package:rpg/layers/domain/use-cases/game/resume_construction_use_case.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late ResumeConstructionUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = ResumeConstructionUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenResumingAnUnknownBuildingThenReturnsUnknownBuilding', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWood()));

    // when
    final result = sut(buildingId: 'building-99');

    // then
    expect(result, ResumeConstructionResult.unknownBuilding);
  });
}
