import '../../../../core/config/constants/enum/blueprint_id.dart';

class BuildOptionEntity {
  final BlueprintId blueprint;
  final int woodCost;
  final bool isAffordable;

  const BuildOptionEntity({required this.blueprint, required this.woodCost, required this.isAffordable});

  @override
  bool operator ==(Object other) =>
      other is BuildOptionEntity &&
      other.blueprint == blueprint &&
      other.woodCost == woodCost &&
      other.isAffordable == isAffordable;

  @override
  int get hashCode => Object.hash(blueprint, woodCost, isAffordable);
}
