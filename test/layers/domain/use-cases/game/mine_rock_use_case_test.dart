import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:farming/core/config/constants/enum/mine_result.dart';
import 'package:farming/layers/domain/entities/player/activity_entity.dart';
import 'package:farming/layers/domain/use-cases/game/mine_rock_use_case.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../../mocks/domain/entities/game/game_session_entity_mock.dart';
import '../../../../mocks/domain/repositories/repository_mocks.mocks.dart';
import '../../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../../mocks/domain/entities/rock/rock_entity_mock.dart';
import '../../../../mocks/domain/world/world_mock.dart';

void main() {
  late MockGameSessionRepository sessionRepository;
  late MineRockUseCase sut;

  setUp(() {
    sessionRepository = MockGameSessionRepository();
    sut = MineRockUseCase(sessionRepository: sessionRepository);
  });

  World playing(World world) {
    when(sessionRepository.current()).thenReturn(GameSessionEntityMock.playing(world));
    return world;
  }

  test('testWhenMiningAKnownRockWithAPickaxeThenThePlayerGoesToMineIt', () {
    // given
    final world = playing(WorldMock.restored(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]));

    // when
    final result = sut(rockId: 'rock-1');

    // then
    expect(result, MineResult.ok);
    expect(world.player.activity, isA<WalkingActivityEntity>());
  });

  test('testWhenMiningWithoutAPickaxeThenNoPickaxeIsReported', () {
    // given
    playing(WorldMock.restored(player: PlayerEntityMock.withAxe, rocks: [RockEntityMock.intact]));

    // when
    final result = sut(rockId: 'rock-1');

    // then
    expect(result, MineResult.noPickaxe);
  });

  test('testWhenMiningAnUnknownRockThenUnknownRockIsReported', () {
    // given
    playing(WorldMock.restored(player: PlayerEntityMock.withPickaxe, rocks: [RockEntityMock.intact]));

    // when
    final result = sut(rockId: 'rock-99');

    // then
    expect(result, MineResult.unknownRock);
  });
}
