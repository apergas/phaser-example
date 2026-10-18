import 'package:farming/layers/data/datasources/save/local/dbo/save_item_dbo.dart';

abstract final class SaveItemDBOMock {
  static const SaveItemDBO axe = SaveItemDBO(id: 'axe-1', kind: 'axe', x: 150, y: 100);
  static const SaveItemDBO withoutId = SaveItemDBO(kind: 'axe', x: 150, y: 100);
  static const SaveItemDBO unknownKind = SaveItemDBO(id: 'axe-1', kind: 'hammer', x: 150, y: 100);
  static const SaveItemDBO withoutX = SaveItemDBO(id: 'axe-1', kind: 'axe', y: 100);
  static const SaveItemDBO withoutY = SaveItemDBO(id: 'axe-1', kind: 'axe', x: 150);
  static const Map<String, dynamic> wrongTypes = {'id': 'axe-1', 'kind': 3, 'x': 150, 'y': 100};
}
