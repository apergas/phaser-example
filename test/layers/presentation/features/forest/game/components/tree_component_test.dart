import 'dart:math' as math;

import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/tree_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

double _degrees(double value) => value * math.pi / 180;

void main() {
  testWithFlameGame('testWhenTappingATreeThenOnlyOpaquePixelsCount', (game) async {
    // given
    final tree = TreeComponent(assets: LpcAssetsMock.create(), tree: ForestDataMock.tree);
    await game.ensureAdd(tree);

    // when
    final onOpaque = tree.containsPoint(Vector2(101, 113));
    final onTransparent = tree.containsPoint(Vector2(97, 113));
    final outside = tree.containsPoint(Vector2(110, 113));

    // then
    expect(tree.priority, RenderDepth.bySortY(120));
    expect(onOpaque, isTrue);
    expect(onTransparent, isFalse);
    expect(outside, isFalse);
  });

  testWithFlameGame('testWhenHitFromTheLeftThenShakesRightAndSettles', (game) async {
    // given
    final tree = TreeComponent(assets: LpcAssetsMock.create(), tree: ForestDataMock.tree);
    await game.ensureAdd(tree);

    // when
    tree.hit(90);
    game.update(0.07);
    final peak = tree.angle;
    game.update(0.08);

    // then
    expect(peak, closeTo(_degrees(3), 1e-9));
    expect(tree.angle, 0);
  });

  testWithFlameGame('testWhenFelledFromTheRightThenFallsLeftFadesAndIsRemoved', (game) async {
    // given
    final tree = TreeComponent(assets: LpcAssetsMock.create(), tree: ForestDataMock.tree);
    await game.ensureAdd(tree);

    // when
    tree.fell(110);
    game.update(0.35);
    final halfwayAngle = tree.angle;
    final halfwayOpacity = tree.opacity;
    final tappableWhileFalling = tree.containsPoint(Vector2(101, 113));
    game.update(0.36);
    await game.ready();

    // then
    expect(halfwayAngle, closeTo(_degrees(-85 * 0.25), 1e-9));
    expect(halfwayOpacity, closeTo(0.75, 0.01));
    expect(tappableWhileFalling, isFalse);
    expect(tree.isMounted, isFalse);
  });
}
