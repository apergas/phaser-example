import 'dart:math';

import 'package:collection/collection.dart';

import '../../../core/config/constants/enum/blueprint_id.dart';
import '../../../core/config/constants/enum/resource.dart';
import '../../../core/config/constants/enum/tool_kind.dart';
import '../../../core/config/constants/enum/upgrade_id.dart';
import '../entities/upgrade/upgrade_entity.dart';

abstract final class Upgrades {
  static const BlueprintId building = BlueprintId.workshop;

  static const UpgradeEntity ironAxe = UpgradeEntity(
    id: UpgradeId.ironAxe,
    tool: ToolKind.axe,
    level: 2,
    cost: {Resource.wood: 15, Resource.stone: 15},
  );

  static const UpgradeEntity ironPickaxe = UpgradeEntity(
    id: UpgradeId.ironPickaxe,
    tool: ToolKind.pickaxe,
    level: 2,
    cost: {Resource.wood: 10, Resource.stone: 20},
  );

  static const List<UpgradeEntity> all = [ironAxe, ironPickaxe];

  static UpgradeEntity of(UpgradeId id) => all.firstWhere((upgrade) => upgrade.id == id);

  static UpgradeEntity? reached(ToolKind tool, int level) =>
      all.lastWhereOrNull((upgrade) => upgrade.tool == tool && upgrade.level <= level);

  static int maxLevel(ToolKind tool) =>
      all.where((upgrade) => upgrade.tool == tool).fold(1, (level, upgrade) => max(level, upgrade.level));
}
