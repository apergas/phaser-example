import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/atlas_sprite_component.dart';

import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  testWithFlameGame('testWhenPlacingAnAtlasSpriteThenItsPivotSitsOnThePoint', (game) async {
    // given
    final sprite = AtlasSpriteComponent(
      assets: LpcAssetsMock.create(),
      frameName: SpriteNames.stump,
      at: const PositionEntity(x: 100, y: 120),
      priority: 7,
    );

    // when
    await game.ensureAdd(sprite);

    // then
    expect(sprite.bounds, const Rect.fromLTWH(96, 112, 8, 8));
    expect(sprite.boundsContain(Vector2(104, 120)), isTrue);
    expect(sprite.boundsContain(Vector2(104.5, 120)), isFalse);
    expect(sprite.priority, 7);
    expect(sprite.paint.filterQuality, FilterQuality.none);
  });
}
