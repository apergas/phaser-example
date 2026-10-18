import 'package:farming/layers/domain/entities/rock/rock_entity.dart';
import 'package:farming/layers/domain/world/world_state.dart';

import '../entities/player/player_entity_mock.dart';
import '../entities/tree/tree_entity_mock.dart';

abstract final class WorldStateMock {
  static WorldState make({double width = 200, double height = 100, List<RockEntity> rocks = const []}) {
    return WorldState(
      width: width,
      height: height,
      player: PlayerEntityMock.mock,
      trees: [TreeEntityMock.mock],
      decorations: [],
      rocks: rocks,
      buildings: [],
    );
  }
}
