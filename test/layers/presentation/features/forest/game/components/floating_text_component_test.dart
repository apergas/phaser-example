import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/floating_text_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/render_depth.dart';

import '../../../../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  testWithFlameGame('testWhenAddedThenShowsTheTextAboveThePointOverEverything', (game) async {
    // given
    final floating = FloatingTextComponent(
      text: Internationalize.arenaDamage(amount: 8),
      at: const PositionEntity(x: 100, y: 120),
    );

    // when
    await game.ensureAdd(floating);

    // then
    expect(floating.text, Internationalize.arenaDamage(amount: 8));
    expect(floating.position, Vector2(100, 100));
    expect(floating.anchor, Anchor.bottomCenter);
    expect(floating.priority, RenderDepth.overlay);
    expect(floating.alpha, 1);
  });

  testWithFlameGame('testWhenTimePassesThenRisesFadesAndRemovesItself', (game) async {
    // given
    final floating = FloatingTextComponent(
      text: Internationalize.arenaDamage(amount: 4),
      at: const PositionEntity(x: 100, y: 120),
    );
    await game.ensureAdd(floating);

    // when
    game.update(0.45);
    final halfwayY = floating.position.y;
    final halfwayAlpha = floating.alpha;
    game.update(0.225);
    final fadingAlpha = floating.alpha;
    game.update(0.3);
    await game.ready();

    // then
    expect(halfwayY, closeTo(87.27, 0.01));
    expect(halfwayAlpha, closeTo(1, 0.001));
    expect(fadingAlpha, closeTo(0.5, 0.001));
    expect(floating.isMounted, isFalse);
  });
}
