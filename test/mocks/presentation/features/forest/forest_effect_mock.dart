import 'package:rpg/layers/presentation/features/forest/models/forest_effect.dart';

abstract final class ForestEffectMock {
  static TreeFelledEffect get treeFelled => TreeFelledEffect(treeId: 'tree-1', fromX: 180);

  static TreeFelledEffect get treeFelledCopy => TreeFelledEffect(treeId: 'tree-1', fromX: 180);

  static TreeHitEffect get treeHit => TreeHitEffect(treeId: 'tree-1', fromX: 180);
}
