import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';
import 'package:rpg/layers/presentation/features/arena/game/arena_game.dart';

import '../../../../../helpers/spanish_translations.dart';
import '../../../../../mocks/presentation/features/arena/arena_bloc_fake.dart';
import '../../../../../mocks/presentation/features/arena/arena_data_mock.dart';
import '../../../../../mocks/presentation/features/arena/game/arena_assets_loader_fake.dart';
import '../../../../../mocks/presentation/features/arena/game/arena_assets_mock.dart';
import '../../../../../mocks/presentation/features/forest/game/update_probe_component_fake.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late ArenaBlocFake bloc;
  late ArenaAssetsLoaderFake loader;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    bloc = ArenaBlocFake(ArenaSuccess(data: ArenaDataMock.preview));
    loader = ArenaAssetsLoaderFake(ArenaAssetsMock.create());
  });

  testWithGame<ArenaGame>(
    'testWhenLoadedThenBuildsTheSceneFromTheBlocState',
    () => ArenaGame(bloc: bloc, assetsLoader: loader),
    (
      game,
    ) async {
      // given
      await game.ready();

      // when
      final scene = game.scene;

      // then
      expect(loader.loadCalled, isTrue);
      expect(game.isReady, isTrue);
      expect(scene!.fighters.keys, ['hero-0', 'enemy-0']);
    },
  );

  testWithGame<ArenaGame>(
    'testWhenNothingIsReplayingThenDoesNotTick',
    () => ArenaGame(bloc: bloc, assetsLoader: loader),
    (
      game,
    ) async {
      // given
      await game.ready();

      // when
      game.update(0.016);
      await _settle();

      // then
      expect(bloc.events.whereType<ArenaReplayTicked>(), isEmpty);
    },
  );

  testWithGame<ArenaGame>(
    'testWhenReplayingThenTicksWithTheFrameTimeCappedLikeTheForest',
    () => ArenaGame(
      bloc: bloc = ArenaBlocFake(ArenaSuccess(data: ArenaDataMock.replaying)),
      assetsLoader: loader,
    ),
    (game) async {
      // given
      await game.ready();
      final probe = UpdateProbeComponentFake();
      await game.world.add(probe);
      await game.ready();

      // when
      game.update(0.016);
      game.update(0.5);
      await _settle();

      // then
      final ticks = bloc.events.whereType<ArenaReplayTicked>().map((event) => event.deltaMs);
      expect(ticks, containsAllInOrder([closeTo(16, 1e-9), closeTo(100, 1e-9)]));
      expect(probe.updates, [closeTo(0.016, 1e-9), closeTo(0.1, 1e-9)]);
    },
  );
}
