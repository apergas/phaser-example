import '../../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../../core/config/constants/enum/construction_rejection.dart';
import '../../../../domain/entities/geometry/position_entity.dart';

class PlacementData {
  final BlueprintId blueprint;
  final PositionEntity position;
  final ConstructionRejection? invalidReason;

  const PlacementData({required this.blueprint, required this.position, required this.invalidReason});

  bool get isValid => invalidReason == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlacementData &&
          other.blueprint == blueprint &&
          other.position == position &&
          other.invalidReason == invalidReason;

  @override
  int get hashCode => Object.hash(blueprint, position, invalidReason);
}
