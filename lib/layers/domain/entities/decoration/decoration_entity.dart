import '../../../../core/config/constants/enum/decoration_kind.dart';
import '../geometry/position_entity.dart';

class DecorationEntity {
  final String id;
  final DecorationKind kind;
  final PositionEntity position;

  const DecorationEntity({required this.id, required this.kind, required this.position});

  DecorationEntity copyWith({String? id, DecorationKind? kind, PositionEntity? position}) {
    return DecorationEntity(id: id ?? this.id, kind: kind ?? this.kind, position: position ?? this.position);
  }

  @override
  bool operator ==(Object other) =>
      other is DecorationEntity && other.id == id && other.kind == kind && other.position == position;

  @override
  int get hashCode => Object.hash(id, kind, position);
}
