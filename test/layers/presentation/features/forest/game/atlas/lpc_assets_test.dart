import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/forest/player_sheet.dart';
import 'package:rpg/layers/presentation/features/forest/game/atlas/sprite_names.dart';

import '../../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('testWhenCheckingAFramePixelThenUsesTheSolidAlphaThreshold', () {
    // given
    final assets = LpcAssetsMock.create();
    final frame = assets.frame(SpriteNames.house);

    // when
    final left = assets.isOpaque(frame, 1, 3);
    final right = assets.isOpaque(frame, 6, 3);
    final outside = assets.isOpaque(frame, 8, 3);

    // then
    expect(left, isFalse);
    expect(right, isTrue);
    expect(outside, isFalse);
  });

  test('testWhenAskingForAnUnknownFrameThenThrows', () {
    // given
    final assets = LpcAssetsMock.create();

    // when
    void lookUp() => assets.frame('tree-palm');

    // then
    expect(lookUp, throwsArgumentError);
  });

  test('testWhenAskingForASpriteThenCutsTheFrameRectangle', () {
    // given
    final assets = LpcAssetsMock.create();

    // when
    final sprite = assets.sprite(SpriteNames.stump);

    // then
    expect(sprite.srcSize.x, 8);
    expect(sprite.srcSize.y, 8);
    expect(assets.sheet(PlayerSheet.chop), same(assets.heroChop));
  });
}
