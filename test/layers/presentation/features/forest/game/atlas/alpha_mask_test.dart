import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/alpha_mask.dart';

void main() {
  test('testWhenReadingAlphaThenReturnsTheFourthByteOfThePixel', () {
    // given
    final mask = AlphaMask(width: 2, height: 1, rgba: Uint8List.fromList([10, 20, 30, 0, 40, 50, 60, 255]));

    // when
    final transparent = mask.alphaAt(0, 0);
    final opaque = mask.alphaAt(1, 0);

    // then
    expect(transparent, 0);
    expect(opaque, 255);
  });

  test('testWhenReadingOutsideTheImageThenIsTransparent', () {
    // given
    final mask = AlphaMask(width: 2, height: 1, rgba: Uint8List.fromList([0, 0, 0, 255, 0, 0, 0, 255]));

    // when
    final outside = [mask.alphaAt(-1, 0), mask.alphaAt(2, 0), mask.alphaAt(0, 1)];

    // then
    expect(outside, [0, 0, 0]);
  });
}
