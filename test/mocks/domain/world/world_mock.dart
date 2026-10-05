import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/item/ground_item_entity.dart';
import 'package:rpg/layers/domain/entities/player/player_entity.dart';
import 'package:rpg/layers/domain/entities/tree/tree_entity.dart';
import 'package:rpg/layers/domain/world/world.dart';

import '../entities/player/player_entity_mock.dart';
import '../entities/tree/tree_entity_mock.dart';

abstract final class WorldMock {
  static World make({
    PlayerEntity player = PlayerEntityMock.mock,
    List<TreeEntity> trees = const [],
    List<GroundItemEntity> items = const [],
  }) {
    return World(width: 1000, height: 1000, player: player, trees: trees, items: items);
  }

  static World small() {
    return World(width: 200, height: 100, player: PlayerEntityMock.centered, trees: const []);
  }

  static World withAxeAndTree() => make(player: PlayerEntityMock.withAxe, trees: [TreeEntityMock.mock]);

  static World withAxeAndTreeWithNeighbour() {
    return make(player: PlayerEntityMock.withAxeBelowTree, trees: [TreeEntityMock.mock, TreeEntityMock.neighbour]);
  }

  static World withAxeAndTreeInTheWay() {
    return make(player: PlayerEntityMock.withAxe, trees: [TreeEntityMock.farEast, TreeEntityMock.inTheWay]);
  }

  static World withTreeBlockingPath() => make(trees: [TreeEntityMock.blockingPath]);

  static World withFifteenWood() => make(player: PlayerEntityMock.withFifteenWood);

  static World withSeventeenWood() => make(player: PlayerEntityMock.withSeventeenWood);

  static World withFifteenWoodAndTreeAtSite() {
    return make(player: PlayerEntityMock.withFifteenWood, trees: [TreeEntityMock.atSite]);
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
