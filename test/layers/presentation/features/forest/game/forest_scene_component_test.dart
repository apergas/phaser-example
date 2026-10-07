import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/placement_ghost_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/ground_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/components/tree_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/forest_scene_component.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_burst_component.dart';

import '../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';

Future<ForestSceneComponent> _mountedScene(FlameGame game) async {
  final scene = ForestSceneComponent(assets: LpcAssetsMock.create(), random: math.Random(1));
  await game.ensureAdd(scene);
  scene.show(ForestDataMock.initial);
  await game.ready();
  return scene;
}

void main() {
  testWithFlameGame('testWhenShowingTheFirstStateThenBuildsTheWorldFromTheLevel', (game) async {
    // given
    final scene = ForestSceneComponent(assets: LpcAssetsMock.create(), random: math.Random(1));
    await game.ensureAdd(scene);

    // when
    scene.show(ForestDataMock.initial);
    await game.ready();

    // then
    expect(scene.trees.keys, ['tree-1', 'tree-2']);
    expect(scene.items.keys, ['axe']);
    expect(scene.clutter, hasLength(1));
    expect(scene.children.whereType<GroundComponent>(), hasLength(1));
    expect(scene.player, isNotNull);
    expect(scene.ghost, isNull);
  });

  testWithFlameGame('testWhenCanopiesOverlapThenTheFrontTreeIsTapped', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    final overlap = scene.treeAt(Vector2(103, 117));
    final backOnly = scene.treeAt(Vector2(101, 113));
    final gap = scene.treeAt(Vector2(97, 115));

    // then
    expect(overlap, 'tree-2');
    expect(backOnly, 'tree-1');
    expect(gap, isNull);
  });

  testWithFlameGame('testWhenATreeIsHitThenWoodChipsFly', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.treeHit);
    await game.ready();

    // then
    expect(scene.children.whereType<ParticleBurstComponent>(), hasLength(1));
  });

  testWithFlameGame('testWhenATreeIsFelledThenFallsLeavesAStumpAndIsNoLongerTappable', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.treeFelled);
    await game.ready();
    final fallingTrees = scene.children.whereType<TreeComponent>().length;
    game.update(0.71);
    await game.ready();

    // then
    expect(scene.trees.keys, ['tree-2']);
    expect(fallingTrees, 2);
    expect(scene.children.whereType<TreeComponent>(), hasLength(1));
    expect(scene.clutter, hasLength(2));
    expect(scene.treeAt(Vector2(101, 113)), isNull);
  });

  testWithFlameGame('testWhenTheAxeIsPickedUpThenItPopsAndVanishes', (game) async {
    // given
    final scene = await _mountedScene(game);
    final axe = scene.items['axe']!;

    // when
    scene.show(ForestDataMock.axePickedUp);
    game.update(0.31);
    await game.ready();

    // then
    expect(scene.items, isEmpty);
    expect(axe.isMounted, isFalse);
  });

  testWithFlameGame('testWhenAnItemLeavesTheWorldWithoutEffectThenIsRemoved', (game) async {
    // given
    final scene = await _mountedScene(game);
    final axe = scene.items['axe']!;

    // when
    scene.show(ForestDataMock.axeGone);
    await game.ready();

    // then
    expect(scene.items, isEmpty);
    expect(axe.isMounted, isFalse);
  });

  testWithFlameGame('testWhenAHouseIsPlacedThenAppearsAndClearsTheDecorationUnderIt', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.housePlaced);
    await game.ready();

    // then
    expect(scene.buildings.keys, ['building-1']);
    expect(scene.clutter, isEmpty);
  });

  testWithFlameGame('testWhenAHouseIsHammeredThenRaisesDustAndProgresses', (game) async {
    // given
    final scene = await _mountedScene(game);
    scene.show(ForestDataMock.housePlaced);
    await game.ready();

    // when
    scene.show(ForestDataMock.houseHammered);
    await game.ready();

    // then
    expect(scene.buildings['building-1']!.progress, 0.5);
    expect(scene.children.whereType<ParticleBurstComponent>(), hasLength(1));
  });

  testWithFlameGame('testWhenPlacementStartsAndEndsThenTheGhostComesAndGoes', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.placing);
    await game.ready();
    final ghostWhilePlacing = scene.ghost;
    scene.show(ForestDataMock.initial);
    await game.ready();

    // then
    expect(ghostWhilePlacing, isNotNull);
    expect(ghostWhilePlacing!.isValid, isTrue);
    expect(scene.ghost, isNull);
    expect(ghostWhilePlacing.isMounted, isFalse);
  });

  testWithFlameGame('testWhenGearIsBoughtThenSparklesBurstOnTheHero', (game) async {
    // given
    final scene = await _mountedScene(game);

    // when
    scene.show(ForestDataMock.gearPurchased);
    await game.ready();

    // then
    final bursts = scene.children.whereType<ParticleBurstComponent>();
    expect(bursts, hasLength(1));
    expect(bursts.single.priority, greaterThan(scene.player!.priority));
  });

  testWithFlameGame('testWhenThePlacedBlueprintChangesThenTheGhostIsReplaced', (game) async {
    // given
    final scene = await _mountedScene(game);
    scene.show(ForestDataMock.placing);
    await game.ready();
    final houseGhost = scene.ghost!;

    // when
    scene.show(ForestDataMock.placingForge);
    await game.ready();

    // then
    expect(houseGhost.isMounted, isFalse);
    expect(scene.ghost, isNot(same(houseGhost)));
    expect(scene.ghost!.blueprint, BlueprintId.forge);
    expect(scene.ghost!.isMounted, isTrue);
    expect(scene.children.whereType<PlacementGhostComponent>(), hasLength(1));
  });

  testWithFlameGame('testWhenShowingTheSameSnapshotTwiceThenComponentCountsStayTheSame', (game) async {
    // given
    final scene = await _mountedScene(game);
    final childrenBefore = scene.children.length;

    // when
    scene.show(ForestDataMock.initial);
    await game.ready();

    // then
    expect(scene.children.length, childrenBefore);
    expect(scene.trees.keys, ['tree-1', 'tree-2']);
    expect(scene.items.keys, ['axe']);
    expect(scene.clutter, hasLength(1));
    expect(scene.buildings, isEmpty);
    expect(scene.children.whereType<GroundComponent>(), hasLength(1));
  });
}
