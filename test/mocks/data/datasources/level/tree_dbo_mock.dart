import 'package:rpg/layers/data/datasources/level/local/dbo/tree_dbo.dart';

abstract final class TreeDBOMock {
  static const firstGenerated = TreeDBO(
    id: 'tree-1',
    kind: 'broad',
    x: 433.47085868008435,
    y: 155.17504904419184,
    wood: 6,
  );
  static const secondGenerated = TreeDBO(
    id: 'tree-2',
    kind: 'old',
    x: 389.38031366094947,
    y: 465.71301287971437,
    wood: 5,
  );
  static const thirdGenerated = TreeDBO(
    id: 'tree-3',
    kind: 'pine',
    x: 721.9763031136245,
    y: 187.9368040524423,
    wood: 6,
  );
  static const lastGenerated = TreeDBO(
    id: 'tree-70',
    kind: 'dense',
    x: 1487.0892029069364,
    y: 676.5116280969232,
    wood: 6,
  );
  static const firstGeneratedTrees = [firstGenerated, secondGenerated, thirdGenerated];
  static const withoutId = TreeDBO(kind: 'pine', x: 1, y: 2);
}
