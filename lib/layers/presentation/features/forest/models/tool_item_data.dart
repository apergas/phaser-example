import '../../../../../core/config/constants/enum/tool_kind.dart';

class ToolItemData {
  final ToolKind tool;
  final String name;
  final bool isOwned;

  const ToolItemData({required this.tool, required this.name, required this.isOwned});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolItemData && other.tool == tool && other.name == name && other.isOwned == isOwned;

  @override
  int get hashCode => Object.hash(tool, name, isOwned);
}
