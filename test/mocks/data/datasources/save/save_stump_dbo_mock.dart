import 'package:farming/layers/data/datasources/save/local/dbo/save_stump_dbo.dart';

abstract final class SaveStumpDBOMock {
  static const SaveStumpDBO almostSapling = SaveStumpDBO(
    id: 'tree-1',
    kind: 'pine',
    x: 200,
    y: 100,
    elapsedMs: 59999,
  );
  static const SaveStumpDBO elsewhereAlmostSapling = SaveStumpDBO(
    id: 'tree-2',
    kind: 'pine',
    x: 200,
    y: 300,
    elapsedMs: 59999,
  );
  static const SaveStumpDBO otherSapling = SaveStumpDBO(id: 'tree-9', kind: 'pine', x: 200, y: 100, elapsedMs: 60000);
  static const SaveStumpDBO fresh = SaveStumpDBO(id: 'tree-1', kind: 'pine', x: 200, y: 100);
  static const SaveStumpDBO withNegativeElapsed = SaveStumpDBO(
    id: 'tree-1',
    kind: 'pine',
    x: 200,
    y: 100,
    elapsedMs: -1,
  );
  static const SaveStumpDBO withoutId = SaveStumpDBO(kind: 'pine', x: 200, y: 100);
  static const SaveStumpDBO unknownKind = SaveStumpDBO(id: 'tree-1', kind: 'palm', x: 200, y: 100);
  static const SaveStumpDBO withoutX = SaveStumpDBO(id: 'tree-1', kind: 'pine', y: 100);
  static const SaveStumpDBO withoutY = SaveStumpDBO(id: 'tree-1', kind: 'pine', x: 200);
  static const Map<String, dynamic> wrongTypes = {'id': 'tree-1', 'kind': 'pine', 'x': 200, 'y': 100, 'elapsedMs': 'a'};
}
