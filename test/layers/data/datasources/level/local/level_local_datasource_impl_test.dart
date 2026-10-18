import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/config/constants/enum/decoration_kind.dart';
import 'package:farming/core/config/constants/enum/tree_kind.dart';
import 'package:farming/core/utils/kebab_case.dart';
import 'package:farming/layers/data/datasources/level/local/dbo/rock_dbo.dart';
import 'package:farming/layers/data/datasources/level/local/dbo/tree_dbo.dart';
import 'package:farming/layers/data/datasources/level/local/level_local_datasource_impl.dart';

import '../../../../../mocks/data/datasources/level/building_dbo_mock.dart';
import '../../../../../mocks/data/datasources/level/item_dbo_mock.dart';
import '../../../../../mocks/data/datasources/level/point_dbo_mock.dart';
import '../../../../../mocks/data/datasources/level/rock_dbo_mock.dart';
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
    expect(level.items, [ItemDBOMock.pickaxe]);
    expect(level.buildings, [BuildingDBOMock.camp]);
  });

  test('testWhenFetchingThenTwelveRocksMatchTheGoldenPositions', () {
    // given
    final level = sut.fetch();

    // when
    final rocks = level.rocks ?? const <RockDBO>[];

    // then
    expect(rocks, hasLength(12));
    expect(rocks.take(3).toList(), RockDBOMock.firstGeneratedRocks);
    expect(rocks.map((rock) => rock.id), [for (var index = 1; index <= 12; index++) 'rock-$index']);
  });

  test('testWhenFetchingThenRocksKeepClearOfTreesTheSpawnThePickaxeAndEachOther', () {
    // given
    final level = sut.fetch();
    final trees = level.trees ?? const <TreeDBO>[];
    final rocks = level.rocks ?? const <RockDBO>[];
    double distance(double? x1, double? y1, double? x2, double? y2) =>
        sqrt(pow((x1 ?? 0) - (x2 ?? 0), 2) + pow((y1 ?? 0) - (y2 ?? 0), 2));

    // when
    final closestTrunk = [
      for (final rock in rocks)
        for (final tree in trees) distance(rock.x, rock.y, tree.x, tree.y),
    ].reduce(min);
    final closestSpawn = rocks.map((rock) => distance(rock.x, rock.y, 800, 600)).reduce(min);
    final closestPickaxe = rocks.map((rock) => distance(rock.x, rock.y, 1012, 812)).reduce(min);
    final closestRock = [
      for (final (index, rock) in rocks.indexed)
        for (final other in rocks.skip(index + 1)) distance(rock.x, rock.y, other.x, other.y),
    ].reduce(min);

    // then
    expect(closestTrunk, greaterThanOrEqualTo(60));
    expect(closestSpawn, greaterThanOrEqualTo(200));
    expect(closestPickaxe, greaterThanOrEqualTo(80));
    expect(closestRock, greaterThanOrEqualTo(200));
    for (final rock in rocks) {
      final x = rock.x ?? 0;
      final y = rock.y ?? 0;
      final underTree = trees.any(
        (tree) => (x - (tree.x ?? 0)).abs() < 64 && y > (tree.y ?? 0) - 170 && y < (tree.y ?? 0) + 20,
      );
      expect(underTree, isFalse, reason: rock.id);
    }
  });

  test('testWhenFetchingThenNinetyThreeDecorationsKeepTheirIdsAndTheOnesOnRocksThePickaxeOrTheCampAreGone', () {
    // given
    final level = sut.fetch();
    const removed = {6, 12, 17, 30, 34, 37, 40, 42, 49, 68, 78, 81, 85, 105};

    // when
    final ids = (level.decorations ?? const []).map((decoration) => decoration.id).toList();

    // then
    expect(ids, hasLength(93));
    expect(ids, [
      for (var index = 1; index <= 107; index++)
        if (!removed.contains(index)) 'decoration-$index',
    ]);
  });

  test('testWhenFetchingThenNoDecorationIsCloseToTheCampOrARock', () {
    // given
    final level = sut.fetch();
    final rocks = level.rocks ?? const <RockDBO>[];

    // when
    final decorations = level.decorations ?? const [];

    // then
    for (final decoration in decorations) {
      final x = decoration.x ?? 0;
      final y = decoration.y ?? 0;
      expect(sqrt(pow(x - 700, 2) + pow(y - 592, 2)), greaterThanOrEqualTo(64), reason: decoration.id);
      expect(sqrt(pow(x - 1012, 2) + pow(y - 812, 2)), greaterThanOrEqualTo(32), reason: decoration.id);
      for (final rock in rocks) {
        expect(
          sqrt(pow(x - (rock.x ?? 0), 2) + pow(y - (rock.y ?? 0), 2)),
          greaterThanOrEqualTo(48),
          reason: decoration.id,
        );
      }
    }
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
    expect(decorations.length, 93);
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
