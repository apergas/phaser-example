import '../../../../core/config/constants/enum/tree_kind.dart';
import '../../entities/game/stats_entity.dart';

extension StatsRules on StatsEntity {
  int treesFelledOf(TreeKind kind) => treesFelledByKind[kind] ?? 0;

  StatsEntity fellingTree(TreeKind? kind) => copyWith(
    treesFelled: treesFelled + 1,
    treesFelledByKind: kind == null ? null : Map.unmodifiable({...treesFelledByKind, kind: treesFelledOf(kind) + 1}),
  );

  StatsEntity completingBuilding() => copyWith(buildingsCompleted: buildingsCompleted + 1);

  StatsEntity regrowingTree() => copyWith(treesRegrown: treesRegrown + 1);
}
