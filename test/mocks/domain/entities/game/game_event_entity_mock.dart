import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/quest_id.dart';
import 'package:farming/layers/domain/entities/game/game_event_entity.dart';

import '../tree/tree_entity_mock.dart';

abstract final class GameEventEntityMock {
  static const PlayerBlockedEventEntity playerBlocked = PlayerBlockedEventEntity();

  static const TreeHitEventEntity treeHit = TreeHitEventEntity(treeId: 'tree-1', hitsRemaining: 4);

  static const TreeFelledEventEntity treeFelled = TreeFelledEventEntity(treeId: 'tree-1', wood: 6);

  static const BuildingHammeredEventEntity buildingHammered = BuildingHammeredEventEntity(
    buildingId: 'building-1',
    progress: 0.125,
  );

  static const BuildingCompletedEventEntity buildingCompleted = BuildingCompletedEventEntity(
    buildingId: 'building-1',
    blueprint: BlueprintId.house,
  );

  static const QuestCompletedEventEntity gatherWoodCompleted = QuestCompletedEventEntity(questId: QuestId.gatherWood);

  static const QuestCompletedEventEntity fellTenTreesCompleted = QuestCompletedEventEntity(
    questId: QuestId.fellTenTrees,
  );

  static const QuestCompletedEventEntity fellAnOakCompleted = QuestCompletedEventEntity(questId: QuestId.fellAnOak);

  static const QuestCompletedEventEntity buildHouseCompleted = QuestCompletedEventEntity(questId: QuestId.buildHouse);

  static const TreeSproutedEventEntity stumpSprouted = TreeSproutedEventEntity(stumpId: 'tree-1');

  static const TreeSproutedEventEntity otherStumpSprouted = TreeSproutedEventEntity(stumpId: 'tree-2');

  static const TreeRegrownEventEntity pineRegrown = TreeRegrownEventEntity(tree: TreeEntityMock.regrownPine);

  static const RockHitEventEntity rockHit = RockHitEventEntity(rockId: 'rock-1');

  static const RockBrokenEventEntity rockBroken = RockBrokenEventEntity(rockId: 'rock-1', stone: 8);

  static const List<GameEventEntity> all = [
    playerBlocked,
    treeHit,
    treeFelled,
    buildingHammered,
    buildingCompleted,
    gatherWoodCompleted,
  ];

  static List<GameEventEntity> makeAll() {
    final treeId = 'tree-1';
    final buildingId = 'building-1';
    return [
      PlayerBlockedEventEntity(),
      TreeHitEventEntity(treeId: treeId, hitsRemaining: 4),
      TreeFelledEventEntity(treeId: treeId, wood: 6),
      BuildingHammeredEventEntity(buildingId: buildingId, progress: 0.125),
      BuildingCompletedEventEntity(buildingId: buildingId, blueprint: BlueprintId.house),
      QuestCompletedEventEntity(questId: QuestId.gatherWood),
    ];
  }

  static TreeFelledEventEntity makeTreeFelled({int wood = 6}) => TreeFelledEventEntity(treeId: 'tree-1', wood: wood);
}
