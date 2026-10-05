import 'package:rpg/layers/domain/world/world_state.dart';

import '../entities/player/player_entity_mock.dart';
import '../entities/tree/tree_entity_mock.dart';

abstract final class WorldStateMock {
  static WorldState make({double width = 200, double height = 100}) {
    return WorldState(
      width: width,
      height: height,
      player: PlayerEntityMock.mock,
      trees: [TreeEntityMock.mock],
      items: [],
      decorations: [],
    );
  }
}
