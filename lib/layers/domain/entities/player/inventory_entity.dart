import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/tool_kind.dart';

class InventoryEntity {
  final int wood;
  final Set<ToolKind> tools;

  const InventoryEntity({this.wood = 0, this.tools = const {}});

  InventoryEntity copyWith({int? wood, Set<ToolKind>? tools}) {
    return InventoryEntity(wood: wood ?? this.wood, tools: tools ?? this.tools);
  }

  @override
  bool operator ==(Object other) =>
      other is InventoryEntity && other.wood == wood && const SetEquality<ToolKind>().equals(other.tools, tools);

  @override
  int get hashCode => Object.hash(wood, const SetEquality<ToolKind>().hash(tools));
}
