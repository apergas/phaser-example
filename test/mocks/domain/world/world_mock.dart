import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/item/ground_item_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/player/player_entity_mock.dart';

abstract final class WorldMock {
  static World make({
    PlayerEntity player = PlayerEntityMock.mock,
    List<TreeEntity> trees = const [],
    List<GroundItemEntity> items = const [],
  }) {
    return World(width: 1000, height: 1000, player: player, trees: trees, items: items);
  }
}

extension WorldAdvanceFor on World {
  List<GameEventEntity> advanceFor(double totalMs) {
    final events = <GameEventEntity>[];
    var elapsed = 0.0;
    while (elapsed < totalMs) {
      events.addAll(advance(16));
      elapsed += 16;
    }
    return events;
  }
}
