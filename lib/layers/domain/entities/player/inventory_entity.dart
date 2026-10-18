import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/tool_kind.dart';

class InventoryEntity {
  final Set<ToolKind> tools;
  final Map<ToolKind, int> toolLevels;

  const InventoryEntity({this.tools = const {}, this.toolLevels = const {}});

  InventoryEntity copyWith({Set<ToolKind>? tools, Map<ToolKind, int>? toolLevels}) {
    return InventoryEntity(
      tools: tools ?? this.tools,
      toolLevels: toolLevels ?? this.toolLevels,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryEntity &&
      const SetEquality<ToolKind>().equals(other.tools, tools) &&
      const MapEquality<ToolKind, int>().equals(other.toolLevels, toolLevels);

  @override
  int get hashCode =>
      Object.hash(const SetEquality<ToolKind>().hash(tools), const MapEquality<ToolKind, int>().hash(toolLevels));
}
