import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../domain/entities/geometry/position_entity.dart';

class PlacementData {
  final BlueprintId blueprint;
  final PositionEntity position;
  final bool isValid;

  const PlacementData({required this.blueprint, required this.position, required this.isValid});

  PlacementData copyWith({BlueprintId? blueprint, PositionEntity? position, bool? isValid}) {
    return PlacementData(
      blueprint: blueprint ?? this.blueprint,
      position: position ?? this.position,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementData && other.blueprint == blueprint && other.position == position && other.isValid == isValid;

  @override
  int get hashCode => Object.hash(blueprint, position, isValid);
}
