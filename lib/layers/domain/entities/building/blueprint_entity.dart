import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/blueprint_id.dart';
import '../../../../core/config/constants/enum/resource.dart';
import 'placement_rule_entity.dart';

class BlueprintEntity {
  final BlueprintId id;
  final Map<Resource, int> cost;
  final int hitsToBuild;
  final double footprintRadius;
  final bool isBuildable;
  final Set<Resource> accepts;
  final PlacementRuleEntity placementRule;

  const BlueprintEntity({
    required this.id,
    required this.cost,
    required this.hitsToBuild,
    required this.footprintRadius,
    this.isBuildable = true,
    this.accepts = const <Resource>{},
    this.placementRule = const AnywherePlacementRuleEntity(),
  });

  @override
  bool operator ==(Object other) =>
      other is BlueprintEntity &&
      other.id == id &&
      const MapEquality<Resource, int>().equals(other.cost, cost) &&
      other.hitsToBuild == hitsToBuild &&
      other.footprintRadius == footprintRadius &&
      other.isBuildable == isBuildable &&
      const SetEquality<Resource>().equals(other.accepts, accepts) &&
      other.placementRule == placementRule;

  @override
  int get hashCode => Object.hash(
    id,
    const MapEquality<Resource, int>().hash(cost),
    hitsToBuild,
    footprintRadius,
    isBuildable,
    const SetEquality<Resource>().hash(accepts),
    placementRule,
  );
}
