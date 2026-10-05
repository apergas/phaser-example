import 'package:rpg/layers/data/datasources/level/local/dbo/item_dbo.dart';

abstract final class ItemDBOMock {
  static const axe = ItemDBO(id: 'axe', kind: 'axe', x: 856.0, y: 608.0);
  static const upperCaseAxe = ItemDBO(id: 'axe-2', kind: 'AXE', x: 1, y: 2);
  static const withoutId = ItemDBO(kind: 'axe');
  static const unknownKind = ItemDBO(id: 'mystery', kind: 'laser', x: 0, y: 0);
}
