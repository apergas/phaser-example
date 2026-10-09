import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_assets_loader.dart';
import 'package:rpg/layers/presentation/features/arena/game/atlas/arena_sprite_names.dart';

import '../../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('testWhenAskingForAnUnknownFrameThenThrows', () {
    // given
    final assets = ArenaAssetsMock.create();

    // when
    void lookUp() => assets.frame('dragon-idle-0');

    // then
    expect(lookUp, throwsArgumentError);
  });

  test('testWhenAskingForASpriteThenCutsTheFrameRectangle', () {
    // given
    final assets = ArenaAssetsMock.create();

    // when
    final sprite = assets.sprite(ArenaSpriteNames.fence);

    // then
    expect((sprite.srcSize.x, sprite.srcSize.y), (8, 8));
  });

  testWidgets('testWhenLoadingTheRealArtThenTheFeetPivotsAndTheFenceAreRead', (tester) async {
    // given
    final loader = ArenaAssetsLoader();

    // when
    final assets = (await tester.runAsync(loader.load))!;

    // then
    final idle = assets.frame(ArenaSpriteNames.idle(ArenaSpriteNames.hero, 0));
    final slash = assets.frame(ArenaSpriteNames.slash(ArenaSpriteNames.hero, 0));
    final fence = assets.frame(ArenaSpriteNames.fence);
    expect((idle.width, idle.height, idle.pivotY), (64, 64, 0.9688));
    expect((slash.width, slash.height, slash.pivotY), (128, 128, 0.7344));
    expect((fence.width, fence.height, fence.pivotX, fence.pivotY), (64, 32, 0.0, 1.0));
    expect(assets.atlas.width, 1024);
  });

  testWidgets('testWhenLoadingTheRealArtThenTheBeastsStandOnTheirPaws', (tester) async {
    // given
    final loader = ArenaAssetsLoader();

    // when
    final assets = (await tester.runAsync(loader.load))!;

    // then
    final wolf = assets.frame(ArenaSpriteNames.attack('wolf', 0));
    final bearIdle = assets.frame(ArenaSpriteNames.idle('bear', 0));
    final bearAttack = assets.frame(ArenaSpriteNames.attack('bear', 2));
    final bearDown = assets.frame(ArenaSpriteNames.down('bear'));
    expect((wolf.width, wolf.height, wolf.pivotY), (64, 32, 1.0));
    expect((bearIdle.width, bearIdle.height, bearIdle.pivotY), (64, 64, 0.9688));
    expect((bearAttack.pivotY, bearDown.pivotY), (0.9062, 0.8906));
  });
}
