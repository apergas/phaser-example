import 'package:farming/layers/data/datasources/save/local/dbo/save_stats_dbo.dart';

abstract final class SaveStatsDBOMock {
  static const SaveStatsDBO mock = SaveStatsDBO(
    treesFelled: 4,
    treesFelledByKind: {'pine': 3, 'oak': 1},
    buildingsCompleted: 2,
    treesRegrown: 1,
  );
  static const SaveStatsDBO empty = SaveStatsDBO();
  static const SaveStatsDBO unknownKind = SaveStatsDBO(treesFelledByKind: {'palm': 1});
  static const SaveStatsDBO negativeTreesFelled = SaveStatsDBO(treesFelled: -1);
  static const SaveStatsDBO negativeKindCount = SaveStatsDBO(treesFelledByKind: {'pine': -1});
  static const SaveStatsDBO negativeBuildings = SaveStatsDBO(buildingsCompleted: -2);
  static const SaveStatsDBO negativeRegrown = SaveStatsDBO(treesRegrown: -3);
  static const Map<String, dynamic> wrongTypes = {'treesFelled': '4'};
}
