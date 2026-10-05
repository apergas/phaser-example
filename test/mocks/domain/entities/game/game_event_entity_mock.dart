import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';

abstract final class GameEventEntityMock {
  static const ItemPickedUpEventEntity itemPickedUp = ItemPickedUpEventEntity(itemId: 'axe-1', kind: ToolKind.axe);

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

  static const QuestCompletedEventEntity pickUpAxeCompleted = QuestCompletedEventEntity(questId: QuestId.pickUpAxe);

  static const QuestCompletedEventEntity buildHouseCompleted = QuestCompletedEventEntity(questId: QuestId.buildHouse);

  static const List<GameEventEntity> all = [
    itemPickedUp,
    playerBlocked,
    treeHit,
    treeFelled,
    buildingHammered,
    buildingCompleted,
    pickUpAxeCompleted,
  ];

  static List<GameEventEntity> makeAll() {
    final treeId = 'tree-1';
    final buildingId = 'building-1';
    return [
      ItemPickedUpEventEntity(itemId: 'axe-1', kind: ToolKind.axe),
      PlayerBlockedEventEntity(),
      TreeHitEventEntity(treeId: treeId, hitsRemaining: 4),
      TreeFelledEventEntity(treeId: treeId, wood: 6),
      BuildingHammeredEventEntity(buildingId: buildingId, progress: 0.125),
      BuildingCompletedEventEntity(buildingId: buildingId, blueprint: BlueprintId.house),
      QuestCompletedEventEntity(questId: QuestId.pickUpAxe),
    ];
  }

  static TreeFelledEventEntity makeTreeFelled({int wood = 6}) => TreeFelledEventEntity(treeId: 'tree-1', wood: wood);
}
