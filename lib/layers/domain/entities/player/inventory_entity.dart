import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/tool_kind.dart';

class InventoryEntity {
  final Map<Resource, int> resources;
  final Set<ToolKind> tools;

  const InventoryEntity({this.resources = const {}, this.tools = const {}});

  InventoryEntity copyWith({Map<Resource, int>? resources, Set<ToolKind>? tools}) {
    return InventoryEntity(resources: resources ?? this.resources, tools: tools ?? this.tools);
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryEntity &&
      const MapEquality<Resource, int>().equals(other.resources, resources) &&
      const SetEquality<ToolKind>().equals(other.tools, tools);

  @override
  int get hashCode =>
      Object.hash(const MapEquality<Resource, int>().hash(resources), const SetEquality<ToolKind>().hash(tools));
}
