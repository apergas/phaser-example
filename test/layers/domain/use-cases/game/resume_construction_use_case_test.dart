import 'package:farming/core/config/constants/enum/resume_construction_result.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/rules/blueprints.dart';
import 'package:farming/layers/domain/rules/rules.dart';
import 'package:farming/layers/domain/use-cases/game/resume_construction_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late ResumeConstructionUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = ResumeConstructionUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenResumingAnUnknownBuildingThenReturnsUnknownBuilding', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.tenWoodInStock()));

    // when
    final result = sut(buildingId: 'building-99');

    // then
    expect(result, ResumeConstructionResult.unknownBuilding);
  });

  test('testWhenResumingTheBuildingBeingHammeredThenKeepsTheSwing', () {
    // given
    final world = WorldMock.withSeventeenWood();
    world.orderConstruction(Blueprints.house, const PositionEntity(x: 300, y: 100));
    world.advanceFor(3000 + Rules.hammerIntervalMs * 2 + 320);
    final swing = world.player.activity;
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));

    // when
    final result = sut(buildingId: 'building-1');

    // then
    expect(swing, isA<WorkingActivityEntity>().having((activity) => activity.elapsedMs, 'elapsedMs', greaterThan(0)));
    expect(result, ResumeConstructionResult.ok);
    expect(world.player.activity, swing);
  });
}
