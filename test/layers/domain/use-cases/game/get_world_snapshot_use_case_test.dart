import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/layers/domain/use-cases/game/get_world_snapshot_use_case.dart';

import '../../../../mocks/domain/entities/rock/rock_entity_mock.dart';
import '../../../../mocks/domain/entities/tree/stump_entity_mock.dart';
import '../../../../mocks/domain/entities/tree/tree_entity_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';
import '../../../../mocks/domain/game/game_scenario_mock.dart';
import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late GetWorldSnapshotUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = GetWorldSnapshotUseCase(sessionRepository: sessionRepository);
  });

  test('testWhenTakingASnapshotThenReturnsEverythingPlacedInTheWorld', () {
    // given
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(GameScenarioMock.levelWithOneTree()));

    // when
    final snapshot = sut();

    // then
    expect(snapshot.width, 1000);
    expect(snapshot.height, 1000);
    expect(snapshot.trees, [TreeEntityMock.mock]);
    expect(snapshot.decorations, isEmpty);
    expect(snapshot.buildings, isEmpty);
  });

  test('testWhenThereAreStumpsAndRocksThenTheSnapshotListsThemInTheWorldOrder', () {
    // given
    final world = WorldMock.restored(
      stumps: [StumpEntityMock.fresh, StumpEntityMock.elsewhereAlmostSapling],
      rocks: [RockEntityMock.intact],
    );
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));

    // when
    final snapshot = sut();

    // then
    expect(snapshot.stumps, world.stumps);
    expect(snapshot.stumps, [StumpEntityMock.fresh, StumpEntityMock.elsewhereAlmostSapling]);
    expect(snapshot.rocks, [RockEntityMock.intact]);
  });

  test('testWhenATreeRegrowsThenItIsTheLastTreeOfTheSnapshot', () {
    // given
    final world = WorldMock.restored(trees: [TreeEntityMock.neighbour], stumps: [StumpEntityMock.almostReady]);
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    world.advance(50);

    // when
    final snapshot = sut();

    // then
    expect(snapshot.trees, [TreeEntityMock.neighbour, TreeEntityMock.regrownPine]);
    expect(snapshot.stumps, isEmpty);
  });
}
