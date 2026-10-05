import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/quest_id.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../world/extensions/inventory_rules.dart';
import '../world/world.dart';
import 'quest.dart';

abstract final class Quests {
  static final List<Quest> all = [
    _MeasuredQuest(
      id: QuestId.pickUpAxe,
      target: 1,
      measure: (world) => world.player.inventory.hasTool(ToolKind.axe) ? 1 : 0,
    ),
    _MeasuredQuest(id: QuestId.gatherWood, target: 15, measure: (world) => world.player.inventory.wood),
    _MeasuredQuest(
      id: QuestId.buildHouse,
      target: 1,
      measure: (world) =>
          world.buildings.where((building) => building.isComplete && building.blueprint.id == BlueprintId.house).length,
    ),
  ];
}

final class _MeasuredQuest implements Quest {
  const _MeasuredQuest({required this.id, required this.target, required this.measure});

  @override
  final QuestId id;

  @override
  final int target;

  final int Function(World world) measure;

  @override
  int progress(World world) => measure(world);
}
