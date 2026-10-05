import 'package:rpg/layers/presentation/features/forest/game/atlas/atlas_frame.dart';

abstract final class AtlasFrameMock {
  static const AtlasFrame house = AtlasFrame(
    name: 'house',
    x: 0,
    y: 0,
    width: 120,
    height: 191,
    pivotX: 0.5,
    pivotY: 1,
  );
  static const AtlasFrame treeOld = AtlasFrame(
    name: 'tree-old',
    x: 122,
    y: 0,
    width: 150,
    height: 169,
    pivotX: 0.4067,
    pivotY: 0.9941,
  );
  static const AtlasFrame noPivot = AtlasFrame(
    name: 'no-pivot',
    x: 1,
    y: 2,
    width: 3,
    height: 4,
    pivotX: 0.5,
    pivotY: 0.5,
  );
}
