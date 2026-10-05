import 'dart:math';

import 'package:injectable/injectable.dart';

import '../../../../../core/utils/seeded_random.dart';
import '../source/level_local_datasource.dart';
import 'dbo/decoration_dbo.dart';
import 'dbo/item_dbo.dart';
import 'dbo/level_dbo.dart';
import 'dbo/point_dbo.dart';
import 'dbo/tree_dbo.dart';

@Injectable(as: LevelLocalDatasource)
class LevelLocalDatasourceImpl implements LevelLocalDatasource {
  static const double _width = 1600;
  static const double _height = 1200;
  static const int _treeCount = 70;
  static const double _minTreeSpacing = 120;
  static const double _spawnClearance = 200;
  static const double _borderMargin = 60;
  static const int _minWood = 5;
  static const int _maxWood = 6;
  static const int _treeSeed = 42;
  static const int _treeKindSeed = 7;
  static const List<String> _treeKinds = [
    'slim',
    'round',
    'wide',
    'broad',
    'twisted',
    'branches',
    'leaning',
    'lumpy',
    'pine',
    'dome',
    'oak',
    'dense',
    'old',
    'big',
  ];
  static const int _decorationSeed = 1337;
  static const int _decorationAttempts = 107;
  static const int _decorationPlacements = 20;
  static const double _decorationSpacing = 32;
  static const List<String> _decorationKinds = [
    'tall-grass',
    'tall-grass',
    'tall-grass',
    'leaves',
    'leaves',
    'mushrooms',
    'rock',
  ];
  static const double _treeHalfWidth = 64;
  static const double _treeHeight = 170;
  static const double _treeRoots = 20;
  static const double _spawnHalfWidth = 48;
  static const double _spawnAbove = 96;
  static const double _spawnBelow = 48;
  static const double _spawnX = _width / 2;
  static const double _spawnY = _height / 2;
  static const PointDBO _playerStart = PointDBO(x: _spawnX, y: _spawnY);
  static const ItemDBO _axe = ItemDBO(id: 'axe', kind: 'axe', x: _spawnX + 56, y: _spawnY + 8);

  const LevelLocalDatasourceImpl();

  @override
  LevelDBO fetch() {
    final trees = _scatterTrees();
    return LevelDBO(
      width: _width,
      height: _height,
      playerStart: _playerStart,
      trees: trees,
      items: const [_axe],
      decorations: _scatterDecorations(trees),
    );
  }

  List<TreeDBO> _scatterTrees() {
    final random = SeededRandom(_treeSeed);
    final kinds = SeededRandom(_treeKindSeed);
    final trees = <TreeDBO>[];

    var attempt = 0;
    while (attempt < _treeCount * 50 && trees.length < _treeCount) {
      attempt++;
      final x = _borderMargin + random.next() * (_width - _borderMargin * 2);
      final y = _borderMargin + random.next() * (_height - _borderMargin * 2);
      final clearOfSpawn = _distance(x, y, _spawnX, _spawnY) >= _spawnClearance;
      final apart = trees.every((tree) => _distance(x, y, tree.x!, tree.y!) >= _minTreeSpacing);
      if (clearOfSpawn && apart) {
        final wood = _minWood + (random.next() * (_maxWood - _minWood + 1)).floor();
        final kind = _treeKinds[(kinds.next() * _treeKinds.length).floor()];
        trees.add(TreeDBO(id: 'tree-${trees.length + 1}', kind: kind, x: x, y: y, wood: wood));
      }
    }
    return trees;
  }

  List<DecorationDBO> _scatterDecorations(List<TreeDBO> trees) {
    final random = SeededRandom(_decorationSeed);
    final decorations = <DecorationDBO>[];

    bool isFree(double x, double y) {
      final underTree = trees.any(
        (tree) => (x - tree.x!).abs() < _treeHalfWidth && y > tree.y! - _treeHeight && y < tree.y! + _treeRoots,
      );
      final onSpawn = (x - _spawnX).abs() < _spawnHalfWidth && y > _spawnY - _spawnAbove && y < _spawnY + _spawnBelow;
      final onAxe = _distance(x, y, _axe.x!, _axe.y!) < _decorationSpacing;
      final crowded = decorations.any(
        (decoration) => _distance(x, y, decoration.x!, decoration.y!) < _decorationSpacing,
      );
      return !underTree && !onSpawn && !onAxe && !crowded;
    }

    for (var attempt = 0; attempt < _decorationAttempts; attempt++) {
      final kind = _decorationKinds[(random.next() * _decorationKinds.length).floor()];
      for (var placement = 0; placement < _decorationPlacements; placement++) {
        final x = random.next() * _width;
        final y = random.next() * _height;
        if (isFree(x, y)) {
          decorations.add(DecorationDBO(id: 'decoration-${decorations.length + 1}', kind: kind, x: x, y: y));
          break;
        }
      }
    }
    return decorations;
  }

  double _distance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }
}
