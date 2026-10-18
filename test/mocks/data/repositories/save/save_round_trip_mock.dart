import 'package:farming/layers/domain/entities/game/game_session_entity.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/entities/tree/tree_entity.dart';
import 'package:farming/layers/domain/quests/quest_log.dart';
import 'package:farming/layers/domain/world/world.dart';

import '../../../domain/entities/tree/tree_entity_mock.dart';
import '../../../domain/game/save_scenario_mock.dart';

abstract final class SaveRoundTripMock {
  static final List<TreeEntity> trees = [
    TreeEntityMock.oakOfEight.copyWith(hitsTaken: 3),
    TreeEntityMock.oakOfEight.copyWith(id: 'neighbour', position: const PositionEntity(x: 165, y: 100)),
  ];

  static GameSessionEntity session() {
    final world = SaveScenarioMock.everything();
    return GameSessionEntity(
      world: World.restore(
        width: world.width,
        height: world.height,
        player: world.player,
        trees: trees,
        stumps: world.stumps,
        rocks: world.rocks,
        decorations: world.decorations,
        buildings: world.buildings,
        hero: world.hero,
        stats: world.stats,
        stock: world.stock,
        idCounters: world.idCounters,
      ),
      quests: QuestLog(completed: SaveScenarioMock.completedQuests),
    );
  }
}
