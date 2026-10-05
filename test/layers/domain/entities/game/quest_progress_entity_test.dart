import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/layers/domain/entities/game/build_option_entity.dart';
import 'package:rpg/layers/domain/entities/game/quest_progress_entity.dart';

void main() {
  test('testWhenComparingQuestProgressThenEveryFieldMatters', () {
    // given
    const progress = QuestProgressEntity(
      id: QuestId.gatherWood,
      progress: 3,
      target: 15,
      isCompleted: false,
      isCurrent: true,
    );

    // when
    final isEqual =
        progress ==
        const QuestProgressEntity(id: QuestId.gatherWood, progress: 3, target: 15, isCompleted: false, isCurrent: true);
    final notCurrent =
        progress ==
        const QuestProgressEntity(
          id: QuestId.gatherWood,
          progress: 3,
          target: 15,
          isCompleted: false,
          isCurrent: false,
        );

    // then
    expect(isEqual, isTrue);
    expect(notCurrent, isFalse);
  });

  test('testWhenComparingBuildOptionsThenAffordabilityMatters', () {
    // given
    const option = BuildOptionEntity(blueprint: BlueprintId.house, woodCost: 15, isAffordable: true);

    // when
    final isEqual = option == const BuildOptionEntity(blueprint: BlueprintId.house, woodCost: 15, isAffordable: true);
    final notAffordable =
        option == const BuildOptionEntity(blueprint: BlueprintId.house, woodCost: 15, isAffordable: false);

    // then
    expect(isEqual, isTrue);
    expect(notAffordable, isFalse);
  });
}
