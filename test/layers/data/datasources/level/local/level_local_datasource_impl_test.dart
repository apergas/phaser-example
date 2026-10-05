import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/core/utils/kebab_case.dart';
import 'package:rpg/layers/data/datasources/level/local/dbo/tree_dbo.dart';
import 'package:rpg/layers/data/datasources/level/local/level_local_datasource_impl.dart';

import '../../../../../mocks/data/datasources/level/item_dbo_mock.dart';
import '../../../../../mocks/data/datasources/level/point_dbo_mock.dart';
import '../../../../../mocks/data/datasources/level/tree_dbo_mock.dart';

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
    final level = sut.fetch();

    // when
    final trees = level.trees ?? const <TreeDBO>[];

    // then
    final kindCounts = <String?, int>{};
    for (final tree in trees) {
      kindCounts[tree.kind] = (kindCounts[tree.kind] ?? 0) + 1;
    }
    expect(level.width, 1600.0);
    expect(level.height, 1200.0);
    expect(level.playerStart, PointDBOMock.playerStart);
    expect(trees.length, 70);
    expect(trees.take(3).toList(), TreeDBOMock.firstGeneratedTrees);
    expect(trees.last, TreeDBOMock.lastGenerated);
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
    expect(level.items, [ItemDBOMock.axe]);
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

  test('testWhenFetchingThenEveryGeneratedTreeKindMapsToATreeKind', () {
    // given
    final level = sut.fetch();

    // when
    final generated = (level.trees ?? const <TreeDBO>[]).map((tree) => tree.kind).toSet();

    // then
    final known = TreeKind.values.map((kind) => kind.name.toKebabCase()).toSet();
    expect(generated, known);
  });

  test('testWhenFetchingThenEveryGeneratedDecorationKindMapsToADecorationKind', () {
    // given
    final level = sut.fetch();

    // when
    final generated = (level.decorations ?? const []).map((decoration) => decoration.kind).toSet();

    // then
    final known = DecorationKind.values.map((kind) => kind.name.toKebabCase()).toSet();
    expect(generated, known);
  });
}
