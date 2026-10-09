import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/quest_id.dart';
import '../../../core/config/constants/enum/quest_line.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../rules/arena_levels.dart';
import '../world/extensions/arena_rules.dart';
import '../world/extensions/building_rules.dart';
import '../world/extensions/inventory_rules.dart';
import '../world/world.dart';
import 'quest.dart';

abstract final class Quests {
  static final List<Quest> all = List.unmodifiable([
    _MeasuredQuest(
      id: QuestId.pickUpAxe,
      line: QuestLine.village,
      target: 1,
      measure: (world) => world.player.inventory.hasTool(ToolKind.axe) ? 1 : 0,
    ),
    _MeasuredQuest(
      id: QuestId.gatherWood,
      line: QuestLine.village,
      target: 15,
      measure: (world) => world.player.inventory.amount(Resource.wood),
    ),
    _MeasuredQuest(
      id: QuestId.buildHouse,
      line: QuestLine.village,
      target: 1,
      measure: (world) => _built(world, BlueprintId.house),
    ),
    _MeasuredQuest(
      id: QuestId.buildForge,
      line: QuestLine.hero,
      target: 1,
      measure: (world) => _built(world, BlueprintId.forge),
    ),
    _MeasuredQuest(
      id: QuestId.winFirstFight,
      line: QuestLine.hero,
      target: 1,
      measure: (world) => world.hero.clearedLevels.isNotEmpty ? 1 : 0,
    ),
    _MeasuredQuest(
      id: QuestId.buyFirstWeapon,
      line: QuestLine.hero,
      target: 1,
      measure: (world) => world.hero.weaponTier >= 1 ? 1 : 0,
    ),
    _MeasuredQuest(
      id: QuestId.buildArmory,
      line: QuestLine.hero,
      target: 1,
      measure: (world) => _built(world, BlueprintId.armory),
    ),
    _MeasuredQuest(
      id: QuestId.buildMageTower,
      line: QuestLine.hero,
      target: 1,
      measure: (world) => _built(world, BlueprintId.mageTower),
    ),
    _MeasuredQuest(
      id: QuestId.learnASkill,
      line: QuestLine.hero,
      target: 1,
      measure: (world) => world.hero.skills.isNotEmpty ? 1 : 0,
    ),
    _MeasuredQuest(
      id: QuestId.clearHalfArena,
      line: QuestLine.hero,
      target: ArenaLevels.all.length ~/ 2,
      measure: (world) => world.hero.clearedLevels.length,
    ),
    _MeasuredQuest(
      id: QuestId.becomeChampion,
      line: QuestLine.hero,
      target: 1,
      measure: (world) => world.hero.isChampion ? 1 : 0,
    ),
  ]);

  static int _built(World world, BlueprintId id) => world.buildings.hasComplete(id) ? 1 : 0;
}

final class _MeasuredQuest implements Quest {
  const _MeasuredQuest({required this.id, required this.line, required this.target, required this.measure});

  @override
  final QuestId id;

  @override
  final QuestLine line;

  @override
  final int target;

  final int Function(World world) measure;

  @override
  int progress(World world) => measure(world);
}
