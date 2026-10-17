import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import '../../../../core/config/constants/enum/upgrade_option_state.dart';
import 'upgrade_entity.dart';

class UpgradeOptionEntity {
  final UpgradeEntity upgrade;
  final UpgradeOptionState state;
  final Map<Resource, int> missing;

  const UpgradeOptionEntity({required this.upgrade, required this.state, this.missing = const {}});

  bool get canBuy => state == UpgradeOptionState.available;

  UpgradeOptionEntity copyWith({UpgradeEntity? upgrade, UpgradeOptionState? state, Map<Resource, int>? missing}) {
    return UpgradeOptionEntity(
      upgrade: upgrade ?? this.upgrade,
      state: state ?? this.state,
      missing: missing ?? this.missing,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UpgradeOptionEntity &&
      other.upgrade == upgrade &&
      other.state == state &&
      const MapEquality<Resource, int>().equals(other.missing, missing);

  @override
  int get hashCode => Object.hash(upgrade, state, const MapEquality<Resource, int>().hash(missing));

  @override
  String toString() => 'UpgradeOptionEntity(upgrade: ${upgrade.id}, state: $state, missing: $missing)';
}
