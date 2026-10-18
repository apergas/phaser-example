import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/layers/domain/entities/game/stats_entity.dart';

abstract final class StatsEntityMock {
  static const StatsEntity empty = StatsEntity();

  static const StatsEntity afterOnePine = StatsEntity(treesFelled: 1, treesFelledByKind: {TreeKind.pine: 1});

  static const StatsEntity afterOneOak = StatsEntity(treesFelled: 1, treesFelledByKind: {TreeKind.oak: 1});

  static const StatsEntity afterOneUnknownTree = StatsEntity(treesFelled: 1);

  static const StatsEntity afterNineTrees = StatsEntity(treesFelled: 9, treesFelledByKind: {TreeKind.pine: 9});

  static const StatsEntity afterTenTrees = StatsEntity(
    treesFelled: 10,
    treesFelledByKind: {TreeKind.pine: 9, TreeKind.oak: 1},
  );

  static const StatsEntity afterOneHouse = StatsEntity(buildingsCompleted: 1);

  static const StatsEntity afterOneRegrowth = StatsEntity(treesRegrown: 1);
}
