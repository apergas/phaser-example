import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../core/config/constants/enum/resource.dart';

class BuildOptionEntity {
  final BlueprintId blueprint;
  final Map<Resource, int> cost;
  final Map<Resource, int> missing;

  const BuildOptionEntity({required this.blueprint, required this.cost, required this.missing});

  bool get isAffordable => missing.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is BuildOptionEntity &&
      other.blueprint == blueprint &&
      const MapEquality<Resource, int>().equals(other.cost, cost) &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(
    blueprint,
    const MapEquality<Resource, int>().hash(cost),
    const MapEquality<Resource, int>().hash(missing),
  );
}
