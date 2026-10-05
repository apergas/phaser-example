import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';

void main() {
  test('testWhenComparingEventsWithSameValuesThenTheyAreEqual', () {
    // given
    const List<GameEventEntity> events = [
      ItemPickedUpEventEntity(itemId: 'axe-1', kind: ToolKind.axe),
      PlayerBlockedEventEntity(),
      TreeHitEventEntity(treeId: 'tree-1', hitsRemaining: 4),
      TreeFelledEventEntity(treeId: 'tree-1', wood: 6),
      BuildingHammeredEventEntity(buildingId: 'building-1', progress: 0.125),
      BuildingCompletedEventEntity(buildingId: 'building-1', blueprint: BlueprintId.house),
      QuestCompletedEventEntity(questId: QuestId.pickUpAxe),
    ];

    // when
    final copies = <GameEventEntity>[
      const ItemPickedUpEventEntity(itemId: 'axe-1', kind: ToolKind.axe),
      const PlayerBlockedEventEntity(),
      const TreeHitEventEntity(treeId: 'tree-1', hitsRemaining: 4),
      const TreeFelledEventEntity(treeId: 'tree-1', wood: 6),
      const BuildingHammeredEventEntity(buildingId: 'building-1', progress: 0.125),
      const BuildingCompletedEventEntity(buildingId: 'building-1', blueprint: BlueprintId.house),
      const QuestCompletedEventEntity(questId: QuestId.pickUpAxe),
    ];

    // then
    expect(copies, events);
    expect(copies.map((event) => event.hashCode), events.map((event) => event.hashCode));
  });

  test('testWhenEventValuesDifferThenTheyAreNotEqual', () {
    // given
    const felled = TreeFelledEventEntity(treeId: 'tree-1', wood: 6);

    // when
    final isEqual = felled == const TreeFelledEventEntity(treeId: 'tree-1', wood: 5);

    // then
    expect(isEqual, isFalse);
  });
}
