import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/game/render/arena_framing.dart';

void main() {
  test('testWhenFramingTheStageThenTheGrassCoversTheWholeView', () {
    // given
    const phone = Size(844, 390);
    const desktop = Size(1280, 720);

    // when
    final phoneZoom = ArenaFraming.zoom(phone);
    final desktopZoom = ArenaFraming.zoom(desktop);

    // then
    expect(phoneZoom, closeTo(844 / 480, 1e-9));
    expect(desktopZoom, closeTo(1280 / 480, 1e-9));
    expect(ArenaFraming.center, const Offset(240, 135));
  });

  test('testWhenTheViewIsTinyOrHugeThenTheZoomIsClamped', () {
    // given
    const tiny = Size(200, 100);
    const huge = Size(3840, 2160);

    // when
    final tinyZoom = ArenaFraming.zoom(tiny);
    final hugeZoom = ArenaFraming.zoom(huge);

    // then
    expect((tinyZoom, hugeZoom), (1, 3));
  });
}
