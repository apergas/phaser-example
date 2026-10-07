import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../../forest/game/render/render_constants.dart';
import '../bloc/arena_bloc.dart';
import 'arena_scene_component.dart';
import 'arena_state_listener.dart';
import 'atlas/arena_assets_loader.dart';
import 'render/arena_framing.dart';
import 'render/arena_render_constants.dart';

class ArenaGame extends FlameGame {
  final ArenaBloc _bloc;
  final ArenaAssetsLoader _assetsLoader;
  final math.Random? _random;
  ArenaSceneComponent? _scene;

  ArenaGame({required this._bloc, ArenaAssetsLoader? assetsLoader, this._random})
    : _assetsLoader = assetsLoader ?? ArenaAssetsLoader();

  ArenaSceneComponent? get scene => _scene;

  bool get isReady => _scene != null;

  @override
  Color backgroundColor() => const Color(ArenaRenderConstants.backgroundColor);

  @override
  Future<void> onLoad() async {
    final assets = await _assetsLoader.load();
    final scene = ArenaSceneComponent(assets: assets, random: _random);
    await world.add(
      FlameBlocProvider<ArenaBloc, ArenaState>.value(
        value: _bloc,
        children: [
          scene,
          ArenaStateListener(scene: scene),
        ],
      ),
    );
    _scene = scene;
    camera.viewfinder
      ..anchor = Anchor.center
      ..position = Vector2(ArenaFraming.center.dx, ArenaFraming.center.dy);
  }

  @override
  void update(double dt) {
    final frameSeconds = math.min(dt, RenderConstants.maxFrameSeconds);
    camera.viewfinder.zoom = ArenaFraming.zoom(Size(size.x, size.y));
    final state = _bloc.state;
    if (isReady && state is ArenaSuccess && state.data.isReplaying) {
      _bloc.add(ArenaReplayTicked(deltaMs: frameSeconds * 1000));
    }
    super.update(frameSeconds);
  }
}
