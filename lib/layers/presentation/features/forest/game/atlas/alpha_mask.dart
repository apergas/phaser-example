import 'dart:typed_data';
import 'dart:ui';

class AlphaMask {
  final int width;
  final int height;
  final Uint8List rgba;

  AlphaMask({required this.width, required this.height, required this.rgba});

  int alphaAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return 0;
    return rgba[(y * width + x) * 4 + 3];
  }

  static Future<AlphaMask> fromImage(Image image) async {
    final data = await image.toByteData(format: ImageByteFormat.rawRgba);
    return AlphaMask(width: image.width, height: image.height, rgba: data!.buffer.asUint8List());
  }
}
