import 'dart:ui';

import 'package:flame/components.dart';

import '../../../../../../core/config/constants/render_constants.dart';
import '../render/render_depth.dart';

class GroundComponent extends PositionComponent {
  final Image tile;
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;
  Picture? _picture;

  GroundComponent({required this.tile, required double worldWidth, required double worldHeight})
    : super(size: Vector2(worldWidth, worldHeight), priority: RenderDepth.ground);

  static int columnsFor(double width) => (width / RenderConstants.tileSize).ceil();

  static int rowsFor(double height) => (height / RenderConstants.tileSize).ceil();

  @override
  Future<void> onLoad() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const tileSize = RenderConstants.tileSize;
    const source = Rect.fromLTWH(0, 0, tileSize, tileSize);
    for (var row = 0; row < rowsFor(size.y); row++) {
      for (var column = 0; column < columnsFor(size.x); column++) {
        canvas.drawImageRect(
          tile,
          source,
          Rect.fromLTWH(column * tileSize, row * tileSize, tileSize, tileSize),
          _paint,
        );
      }
    }
    _picture = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final picture = _picture;
    if (picture != null) canvas.drawPicture(picture);
  }
}
