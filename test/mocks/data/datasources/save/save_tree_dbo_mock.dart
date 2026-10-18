import 'package:farming/layers/data/datasources/save/local/dbo/save_tree_dbo.dart';

abstract final class SaveTreeDBOMock {
  static const SaveTreeDBO withThreeHitsTaken = SaveTreeDBO(id: 'tree-1', kind: 'oak', x: 200, y: 100, hitsTaken: 3);
  static const SaveTreeDBO neighbour = SaveTreeDBO(id: 'neighbour', kind: 'oak', x: 165, y: 100, hitsTaken: 0);
  static const SaveTreeDBO withoutHits = SaveTreeDBO(id: 'tree-1', kind: 'oak', x: 200, y: 100);
  static const SaveTreeDBO withAlmostAllHits = SaveTreeDBO(id: 'tree-1', kind: 'oak', x: 200, y: 100, hitsTaken: 6);
  static const SaveTreeDBO withAllHits = SaveTreeDBO(id: 'tree-1', kind: 'oak', x: 200, y: 100, hitsTaken: 7);
  static const SaveTreeDBO withNegativeHits = SaveTreeDBO(id: 'tree-1', kind: 'oak', x: 200, y: 100, hitsTaken: -1);
  static const SaveTreeDBO withoutId = SaveTreeDBO(kind: 'oak', x: 200, y: 100);
  static const SaveTreeDBO unknownKind = SaveTreeDBO(id: 'tree-1', kind: 'palm', x: 200, y: 100);
  static const SaveTreeDBO withoutKind = SaveTreeDBO(id: 'tree-1', x: 200, y: 100);
  static const SaveTreeDBO withoutX = SaveTreeDBO(id: 'tree-1', kind: 'oak', y: 100);
  static const SaveTreeDBO withoutY = SaveTreeDBO(id: 'tree-1', kind: 'oak', x: 200);
  static const Map<String, dynamic> wrongTypes = {'id': 7, 'kind': 'oak', 'x': 200, 'y': 100};
  static const Map<String, dynamic> wrongHitsType = {
    'id': 'tree-1',
    'kind': 'oak',
    'x': 200,
    'y': 100,
    'hitsTaken': '3',
  };
  static const Map<String, dynamic> wrongCoordinateType = {'id': 'tree-1', 'kind': 'oak', 'x': '200', 'y': 100};
}
