import 'package:flutter_test/flutter_test.dart';

import '../../../../../../mocks/presentation/features/forest/game/alpha_mask_mock.dart';

void main() {
  test('testWhenReadingAlphaThenReturnsTheFourthByteOfThePixel', () {
    // given
    final mask = AlphaMaskMock.transparentThenOpaque;

    // when
    final transparent = mask.alphaAt(0, 0);
    final opaque = mask.alphaAt(1, 0);

    // then
    expect(transparent, 0);
    expect(opaque, 255);
  });

  test('testWhenReadingOutsideTheImageThenIsTransparent', () {
    // given
    final mask = AlphaMaskMock.allOpaque;

    // when
    final outside = [mask.alphaAt(-1, 0), mask.alphaAt(2, 0), mask.alphaAt(0, 1)];

    // then
    expect(outside, [0, 0, 0]);
  });
}
