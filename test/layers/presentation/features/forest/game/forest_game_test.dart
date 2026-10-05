import 'package:flame/extensions.dart';
import 'package:flame/events.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/game/forest_game.dart';
import 'package:rpg/layers/presentation/features/forest/game/particles/particle_burst_component.dart';

import '../../../../../mocks/presentation/features/forest/forest_bloc_fake.dart';
import '../../../../../mocks/presentation/features/forest/game/forest_data_mock.dart';
import '../../../../../mocks/presentation/features/forest/game/lpc_assets_loader_fake.dart';
import '../../../../../mocks/presentation/features/forest/game/lpc_assets_mock.dart';
import '../../../../../mocks/presentation/features/forest/game/update_probe_component_fake.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late ForestBlocFake bloc;
  late LpcAssetsLoaderFake loader;

  ForestGame createGame() => ForestGame(bloc: bloc, assetsLoader: loader);

  setUp(() {
    bloc = ForestBlocFake(ForestSuccess(data: ForestDataMock.initial));
    loader = LpcAssetsLoaderFake(LpcAssetsMock.create());
  });

  testWithGame<ForestGame>('testWhenLoadedThenBuildsTheSceneFromTheBlocState', createGame, (game) async {
    // given
    await game.ready();

    // when
    final scene = game.world.scene;

    // then
    expect(loader.loadCalled, isTrue);
    expect(game.world.isReady, isTrue);
    expect(scene!.trees.keys, ['tree-1', 'tree-2']);
  });

  testWithGame<ForestGame>('testWhenUpdatingThenTicksTheBlocWithTheFrameTime', createGame, (game) async {
    // given
    await game.ready();

    // when
    game.update(0.016);
    game.update(0.5);
    await _settle();

    // then
    final ticks = bloc.events.whereType<ForestTicked>().map((event) => event.deltaMs);
    expect(ticks, contains(closeTo(16, 1e-9)));
    expect(ticks, contains(closeTo(100, 1e-9)));
  });

  testWithGame<ForestGame>('testWhenAFrameHitchesThenComponentsAdvanceByTheCappedFrameTime', createGame, (
    game,
  ) async {
    // given
    await game.ready();
    final probe = UpdateProbeComponentFake();
    await game.world.add(probe);
    await game.ready();

    // when
    game.update(0.016);
    game.update(0.5);

    // then
    expect(probe.updates, [closeTo(0.016, 1e-9), closeTo(0.1, 1e-9)]);
  });

  testWithGame<ForestGame>(
    'testWhenTheGameHasNotStartedThenDoesNotTick',
    () => ForestGame(bloc: bloc = ForestBlocFake(ForestInitial()), assetsLoader: loader),
    (game) async {
      // given
      await game.ready();

      // when
      game.update(0.016);
      await _settle();

      // then
      expect(bloc.events.whereType<ForestTicked>(), isEmpty);
    },
  );

  testWithGame<ForestGame>('testWhenUpdatingThenTheCameraFramesTheWorldAtZoomTwo', createGame, (game) async {
    // given
    await game.ready();
    game.onGameResize(Vector2(800, 600));

    // when
    game.update(0.016);

    // then
    expect(game.camera.viewfinder.zoom, 2);
    expect(game.camera.viewfinder.position, Vector2(200, 150));
  });

  testWithGame<ForestGame>('testWhenClickingATreeWithTheMouseThenOrdersTheBlocToChopIt', createGame, (game) async {
    // given
    await game.ready();

    // when
    game.world.clickAt(Vector2(101, 113), isMouse: true);
    await _settle();

    // then
    final click = bloc.events.whereType<ForestMapClicked>().single;
    expect(click.treeId, 'tree-1');
    expect(click.isSecondary, isFalse);
    expect(click.position.x, 101);
    expect(click.position.y, 113);
  });

  testWithGame<ForestGame>('testWhenRightClickingThenTheClickIsSecondary', createGame, (game) async {
    // given
    await game.ready();

    // when
    game.world.clickAt(Vector2(300, 250), isMouse: true, isSecondary: true);
    await _settle();

    // then
    final click = bloc.events.whereType<ForestMapClicked>().single;
    expect(click.isSecondary, isTrue);
    expect(click.treeId, isNull);
  });

  testWithGame<ForestGame>(
    'testWhenTappingWhilePlacingThenMovesTheGhostInsteadOfBuilding',
    () => ForestGame(
      bloc: bloc = ForestBlocFake(ForestSuccess(data: ForestDataMock.placing)),
      assetsLoader: loader,
    ),
    (game) async {
      // given
      await game.ready();

      // when
      game.world.clickAt(Vector2(250, 200), isMouse: false);
      await _settle();

      // then
      expect(bloc.events.whereType<ForestMapClicked>(), isEmpty);
      final moved = bloc.events.whereType<ForestPointerMoved>().single;
      expect(moved.position.x, 250);
      expect(moved.position.y, 200);
    },
  );

  testWithGame<ForestGame>(
    'testWhenDraggingWhilePlacingThenMovesTheGhost',
    () => ForestGame(
      bloc: bloc = ForestBlocFake(ForestSuccess(data: ForestDataMock.placing)),
      assetsLoader: loader,
    ),
    (game) async {
      // given
      await game.ready();

      // when
      game.world.dragTo(Vector2(260, 210));
      await _settle();

      // then
      final moved = bloc.events.whereType<ForestPointerMoved>().single;
      expect(moved.position.x, 260);
      expect(moved.position.y, 210);
    },
  );

  testWithGame<ForestGame>('testWhenDraggingWithoutPlacingThenSendsNothing', createGame, (game) async {
    // given
    await game.ready();

    // when
    game.world.dragTo(Vector2(260, 210));
    await _settle();

    // then
    expect(bloc.events, isEmpty);
  });

  testWithGame<ForestGame>(
    'testWhenTheMouseHoversWhilePlacingThenTheGhostFollowsItEveryFrame',
    () => ForestGame(
      bloc: bloc = ForestBlocFake(ForestSuccess(data: ForestDataMock.placing)),
      assetsLoader: loader,
    ),
    (game) async {
      // given
      await game.ready();
      game.onGameResize(Vector2(800, 600));
      game.update(0.016);

      // when
      game.world.mouseMovedTo(Vector2(400, 300));
      game.update(0.016);
      await _settle();

      // then
      final moved = bloc.events.whereType<ForestPointerMoved>().last;
      expect(moved.position.x, closeTo(200, 1e-9));
      expect(moved.position.y, closeTo(150, 1e-9));
    },
  );

  testWithGame<ForestGame>(
    'testWhenDraggingTheMouseWhilePlacingThenTheGhostKeepsFollowingIt',
    () => ForestGame(
      bloc: bloc = ForestBlocFake(ForestSuccess(data: ForestDataMock.placing)),
      assetsLoader: loader,
    ),
    (game) async {
      // given
      await game.ready();
      game.onGameResize(Vector2(800, 600));
      game.update(0.016);
      game.world.onDragStart(
        DragStartEvent(1, game, DragStartDetails(globalPosition: Offset.zero, kind: PointerDeviceKind.mouse)),
      );

      // when
      game.world.onDragUpdate(
        DragUpdateEvent(1, game, DragUpdateDetails(globalPosition: const Offset(400, 300))),
      );
      game.update(0.016);
      await _settle();

      // then
      final moved = bloc.events.whereType<ForestPointerMoved>().last;
      expect(moved.position.x, closeTo(200, 1e-9));
      expect(moved.position.y, closeTo(150, 1e-9));
    },
  );

  testWithGame<ForestGame>('testWhenTheBlocPushesAnEffectThenItIsPlayedExactlyOnce', createGame, (game) async {
    // given
    await game.ready();
    final scene = game.world.scene!;
    final chipsBefore = scene.children.whereType<ParticleBurstComponent>().length;

    // when
    bloc.push(ForestSuccess(data: ForestDataMock.treeHit));
    await _settle();
    await game.ready();
    game.update(0);
    game.update(0);

    // then
    expect(scene.children.whereType<ParticleBurstComponent>().length, chipsBefore + 1);
  });
}
