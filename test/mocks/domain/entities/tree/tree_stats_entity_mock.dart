import 'package:farming/layers/domain/entities/tree/tree_stats_entity.dart';

abstract final class TreeStatsEntityMock {
  static const TreeStatsEntity pine = TreeStatsEntity(woodYield: 4, hitsToFell: 3);

  static const TreeStatsEntity oak = TreeStatsEntity(woodYield: 8, hitsToFell: 7);

  static const TreeStatsEntity old = TreeStatsEntity(woodYield: 9, hitsToFell: 8);

  static const TreeStatsEntity round = TreeStatsEntity(woodYield: 5, hitsToFell: 5);
}
