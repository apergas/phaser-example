import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';

class InventoryEntity {
  final Map<Resource, int> resources;
  final Set<ToolKind> tools;
  final Map<ToolKind, int> toolLevels;

  const InventoryEntity({this.resources = const {}, this.tools = const {}, this.toolLevels = const {}});

  InventoryEntity copyWith({Map<Resource, int>? resources, Set<ToolKind>? tools, Map<ToolKind, int>? toolLevels}) {
    return InventoryEntity(
      resources: resources ?? this.resources,
      tools: tools ?? this.tools,
      toolLevels: toolLevels ?? this.toolLevels,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryEntity &&
      const MapEquality<Resource, int>().equals(other.resources, resources) &&
      const SetEquality<ToolKind>().equals(other.tools, tools) &&
      const MapEquality<ToolKind, int>().equals(other.toolLevels, toolLevels);

  @override
  int get hashCode => Object.hash(
    const MapEquality<Resource, int>().hash(resources),
    const SetEquality<ToolKind>().hash(tools),
    const MapEquality<ToolKind, int>().hash(toolLevels),
  );
}
