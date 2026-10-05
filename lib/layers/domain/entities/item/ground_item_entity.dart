import '../../../../core/config/constants/enum/tool_kind.dart';
import '../geometry/position_entity.dart';

class GroundItemEntity {
  final String id;
  final ToolKind kind;
  final PositionEntity position;

  const GroundItemEntity({required this.id, required this.kind, required this.position});

  GroundItemEntity copyWith({String? id, ToolKind? kind, PositionEntity? position}) {
    return GroundItemEntity(id: id ?? this.id, kind: kind ?? this.kind, position: position ?? this.position);
  }

  @override
  bool operator ==(Object other) =>
      other is GroundItemEntity && other.id == id && other.kind == kind && other.position == position;

  @override
  int get hashCode => Object.hash(id, kind, position);
}
