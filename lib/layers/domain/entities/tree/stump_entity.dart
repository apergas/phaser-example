import '../../../../core/config/constants/enum/tree_kind.dart';
import '../geometry/position_entity.dart';

class StumpEntity {
  final String id;
  final TreeKind kind;
  final PositionEntity position;
  final double elapsedMs;

  const StumpEntity({required this.id, required this.kind, required this.position, this.elapsedMs = 0})
    : assert(elapsedMs >= 0);

  StumpEntity copyWith({String? id, TreeKind? kind, PositionEntity? position, double? elapsedMs}) {
    return StumpEntity(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      position: position ?? this.position,
      elapsedMs: elapsedMs ?? this.elapsedMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StumpEntity &&
      other.id == id &&
      other.kind == kind &&
      other.position == position &&
      other.elapsedMs == elapsedMs;

  @override
  int get hashCode => Object.hash(id, kind, position, elapsedMs);
}
