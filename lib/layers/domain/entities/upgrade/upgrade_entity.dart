import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';
import '../../../../core/config/constants/enum/upgrade_id.dart';

class UpgradeEntity {
  final UpgradeId id;
  final ToolKind tool;
  final int level;
  final Map<Resource, int> cost;

  const UpgradeEntity({required this.id, required this.tool, required this.level, required this.cost})
    : assert(level > 1);

  UpgradeEntity copyWith({UpgradeId? id, ToolKind? tool, int? level, Map<Resource, int>? cost}) {
    return UpgradeEntity(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      level: level ?? this.level,
      cost: cost ?? this.cost,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UpgradeEntity &&
      other.id == id &&
      other.tool == tool &&
      other.level == level &&
      const MapEquality<Resource, int>().equals(other.cost, cost);

  @override
  int get hashCode => Object.hash(id, tool, level, const MapEquality<Resource, int>().hash(cost));
}
