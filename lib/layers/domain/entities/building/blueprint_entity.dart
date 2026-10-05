import '../../../../core/config/constants/enum/blueprint_id.dart';

class BlueprintEntity {
  final BlueprintId id;
  final int woodCost;
  final int hitsToBuild;
  final double footprintRadius;

  const BlueprintEntity({
    required this.id,
    required this.woodCost,
    required this.hitsToBuild,
    required this.footprintRadius,
  });

  @override
  bool operator ==(Object other) =>
      other is BlueprintEntity &&
      other.id == id &&
      other.woodCost == woodCost &&
      other.hitsToBuild == hitsToBuild &&
      other.footprintRadius == footprintRadius;

  @override
  int get hashCode => Object.hash(id, woodCost, hitsToBuild, footprintRadius);
}
