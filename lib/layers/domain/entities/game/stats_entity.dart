import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/tree_kind.dart';

class StatsEntity {
  final int treesFelled;
  final Map<TreeKind, int> treesFelledByKind;
  final int buildingsCompleted;
  final int treesRegrown;

  const StatsEntity({
    this.treesFelled = 0,
    this.treesFelledByKind = const {},
    this.buildingsCompleted = 0,
    this.treesRegrown = 0,
  }) : assert(treesFelled >= 0),
       assert(buildingsCompleted >= 0),
       assert(treesRegrown >= 0);

  StatsEntity copyWith({
    int? treesFelled,
    Map<TreeKind, int>? treesFelledByKind,
    int? buildingsCompleted,
    int? treesRegrown,
  }) {
    return StatsEntity(
      treesFelled: treesFelled ?? this.treesFelled,
      treesFelledByKind: treesFelledByKind ?? this.treesFelledByKind,
      buildingsCompleted: buildingsCompleted ?? this.buildingsCompleted,
      treesRegrown: treesRegrown ?? this.treesRegrown,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StatsEntity &&
      other.treesFelled == treesFelled &&
      const MapEquality<TreeKind, int>().equals(other.treesFelledByKind, treesFelledByKind) &&
      other.buildingsCompleted == buildingsCompleted &&
      other.treesRegrown == treesRegrown;

  @override
  int get hashCode => Object.hash(
    treesFelled,
    const MapEquality<TreeKind, int>().hash(treesFelledByKind),
    buildingsCompleted,
    treesRegrown,
  );
}
