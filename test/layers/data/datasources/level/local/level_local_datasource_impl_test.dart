import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/item_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/point_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/tree_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/level_local_datasource_impl.dart';

void main() {
  late LevelLocalDatasourceImpl sut;

  setUp(() {
    sut = const LevelLocalDatasourceImpl();
  });

  test('testWhenFetchingTwiceThenReturnsTheSameForest', () {
    // given
    final first = sut.fetch();

    // when
    final second = sut.fetch();

    // then
    expect(second, first);
  });

  test('testWhenFetchingThenForestMatchesTheWebVersionExactly', () {
    // given
    const expectedFirstTrees = [
      TreeDBO(id: 'tree-1', kind: 'broad', x: 433.47085868008435, y: 155.17504904419184, wood: 6),
      TreeDBO(id: 'tree-2', kind: 'old', x: 389.38031366094947, y: 465.71301287971437, wood: 5),
      TreeDBO(id: 'tree-3', kind: 'pine', x: 721.9763031136245, y: 187.9368040524423, wood: 6),
    ];

    // when
    final level = sut.fetch();
    final trees = level.trees ?? const <TreeDBO>[];

    // then
    final kindCounts = <String?, int>{};
    for (final tree in trees) {
      kindCounts[tree.kind] = (kindCounts[tree.kind] ?? 0) + 1;
    }
    expect(level.width, 1600.0);
    expect(level.height, 1200.0);
    expect(level.playerStart, const PointDBO(x: 800.0, y: 600.0));
    expect(trees.length, 70);
    expect(trees.take(3).toList(), expectedFirstTrees);
    expect(
      trees.last,
      const TreeDBO(id: 'tree-70', kind: 'dense', x: 1487.0892029069364, y: 676.5116280969232, wood: 6),
    );
    expect(kindCounts, {
      'broad': 3,
      'old': 6,
      'pine': 8,
      'slim': 4,
      'dense': 4,
      'branches': 7,
      'big': 4,
      'lumpy': 4,
      'leaning': 8,
      'oak': 6,
      'round': 5,
      'wide': 6,
      'twisted': 3,
      'dome': 2,
    });
    expect(trees.fold<int>(0, (sum, tree) => sum + (tree.wood ?? 0)), 388);
    expect(level.items, const [ItemDBO(id: 'axe', kind: 'axe', x: 856.0, y: 608.0)]);
  });

  test('testWhenFetchingThenTreesKeepClearOfTheSpawnPoint', () {
    // given
    final level = sut.fetch();

    // when
    final closest = (level.trees ?? const <TreeDBO>[])
        .map((tree) => sqrt(pow((tree.x ?? 0) - 800.0, 2) + pow((tree.y ?? 0) - 600.0, 2)))
        .reduce(min);

    // then
    expect(closest, greaterThanOrEqualTo(200.0));
  });

  test('testWhenFetchingThenDecorationsAreVariedAndNeverUnderATreeOrOnTheSpawn', () {
    // given
    final level = sut.fetch();
    final trees = level.trees ?? const <TreeDBO>[];

    // when
    final decorations = level.decorations ?? const [];

    // then
    expect(decorations.length, greaterThanOrEqualTo(40));
    expect(decorations.map((decoration) => decoration.kind).toSet(), {'tall-grass', 'leaves', 'mushrooms', 'rock'});
    for (final decoration in decorations) {
      final x = decoration.x ?? 0;
      final y = decoration.y ?? 0;
      final underTree = trees.any(
        (tree) => (x - (tree.x ?? 0)).abs() < 64 && y > (tree.y ?? 0) - 170 && y < (tree.y ?? 0) + 20,
      );
      expect(underTree, isFalse);
      expect((x - 800.0).abs() >= 48 || y < 504.0 || y > 648.0, isTrue);
    }
  });
}
