import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/layers/presentation/features/arena/game/arena_scene_component.dart';
import 'package:rpg/layers/presentation/features/arena/game/components/arena_ground_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/floating_text_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_burst_component.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';

Future<ArenaSceneComponent> _mountedScene(FlameGame game) async {
  final scene = ArenaSceneComponent(assets: ArenaAssetsMock.create(), random: math.Random(1));
  await game.ensureAdd(scene);
  scene.show(ArenaDataMock.preview);
  await game.ready();
  return scene;
}

void main() {
  setUpAll(loadSpanishTranslations);

  testWithFlameGame('testWhenShowingTheFirstStateThenBuildsTheStageAndTheFighters', (game) async {
    // given
    final scene = ArenaSceneComponent(assets: ArenaAssetsMock.create(), random: math.Random(1));
    await game.ensureAdd(scene);

    // when
    scene.show(ArenaDataMock.preview);
    await game.ready();

    // then
    expect(scene.children.whereType<ArenaGroundComponent>(), hasLength(1));
    expect(scene.fighters.keys, ['hero-0', 'enemy-0']);
  });

  testWithFlameGame('testWhenTheLevelChangesThenFightersThatLeftAreRemoved', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.heroAlone);
    await game.ready();

    // then
    expect(scene.fighters.keys, ['hero-0']);
  });

  testWithFlameGame('testWhenABlowLandsThenTheDamageFloatsAndBloodSplashes', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.banditHit);
    await game.ready();

    // then
    final texts = scene.children.whereType<FloatingTextComponent>().map((text) => text.text);
    expect(texts, [Internationalize.arenaDamage(amount: 4)]);
    expect(scene.children.whereType<ParticleBurstComponent>(), hasLength(1));
    expect(scene.fighters['enemy-0']!.healthBar.targetFraction, 0.8);
    expect(scene.fighters['enemy-0']!.isBlinkedOut, isFalse);
  });

  testWithFlameGame('testWhenTheHeroDodgesThenTheDodgeFloatsWithoutBlood', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.heroDodged);
    await game.ready();

    // then
    final texts = scene.children.whereType<FloatingTextComponent>().map((text) => text.text);
    expect(texts, [Internationalize.arenaDodge]);
    expect(scene.children.whereType<ParticleBurstComponent>(), isEmpty);
  });

  testWithFlameGame('testWhenTheFightEndsThenTheBarsJumpToTheFinalHealth', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ArenaDataMock.won);
    await game.ready();

    // then
    expect(scene.fighters['enemy-0']!.healthBar.displayedFraction, 0);
    expect(scene.fighters['hero-0']!.healthBar.displayedFraction, closeTo(22 / 30, 1e-9));
  });
}
