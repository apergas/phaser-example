import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/gear_option_state.dart';
import '../../../../core/config/constants/enum/resource.dart';
import 'gear_entity.dart';

class GearOptionEntity {
  final GearEntity gear;
  final GearOptionState state;
  final Map<Resource, int> missing;

  const GearOptionEntity({required this.gear, required this.state, this.missing = const {}});

  bool get canBuy => state == GearOptionState.available;

  GearOptionEntity copyWith({GearEntity? gear, GearOptionState? state, Map<Resource, int>? missing}) {
    return GearOptionEntity(gear: gear ?? this.gear, state: state ?? this.state, missing: missing ?? this.missing);
  }

  @override
  bool operator ==(Object other) =>
      other is GearOptionEntity &&
      other.gear == gear &&
      other.state == state &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(gear, state, const MapEquality<Resource, int>().hash(missing));

  @override
  String toString() => 'GearOptionEntity(gear: ${gear.id}, state: $state, missing: $missing)';
}
