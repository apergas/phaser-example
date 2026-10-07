import 'dart:math' as math;
import 'dart:ui';

import 'arena_render_constants.dart';

abstract final class ArenaFraming {
  static const Offset center = Offset(ArenaRenderConstants.stageWidth / 2, ArenaRenderConstants.stageHeight / 2);

  static double zoom(Size view) {
    final cover = math.max(
      view.width / ArenaRenderConstants.stageWidth,
      view.height / ArenaRenderConstants.stageHeight,
    );
    return cover.clamp(ArenaRenderConstants.minZoom, ArenaRenderConstants.maxZoom).toDouble();
  }
}
