import 'dart:typed_data';

import 'package:rpg/layers/presentation/features/forest/game/atlas/alpha_mask.dart';

abstract final class AlphaMaskMock {
  static AlphaMask get transparentThenOpaque =>
      AlphaMask(width: 2, height: 1, rgba: Uint8List.fromList([10, 20, 30, 0, 40, 50, 60, 255]));

  static AlphaMask get allOpaque =>
      AlphaMask(width: 2, height: 1, rgba: Uint8List.fromList([0, 0, 0, 255, 0, 0, 0, 255]));
}
