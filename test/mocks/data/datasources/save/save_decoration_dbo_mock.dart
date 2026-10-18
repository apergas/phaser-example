import 'package:farming/layers/data/datasources/save/local/dbo/save_decoration_dbo.dart';

abstract final class SaveDecorationDBOMock {
  static const SaveDecorationDBO rock = SaveDecorationDBO(id: 'decoration-1', kind: 'rock', x: 1, y: 2);
  static const SaveDecorationDBO withoutId = SaveDecorationDBO(kind: 'rock', x: 1, y: 2);
  static const SaveDecorationDBO unknownKind = SaveDecorationDBO(id: 'decoration-1', kind: 'flower', x: 1, y: 2);
  static const SaveDecorationDBO withoutX = SaveDecorationDBO(id: 'decoration-1', kind: 'rock', y: 2);
  static const SaveDecorationDBO withoutY = SaveDecorationDBO(id: 'decoration-1', kind: 'rock', x: 1);
  static const Map<String, dynamic> wrongTypes = {'id': 'decoration-1', 'kind': 'rock', 'x': 'one', 'y': 2};
}
