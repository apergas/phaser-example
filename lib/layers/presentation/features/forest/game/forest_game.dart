import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../bloc/forest_bloc.dart';
import 'atlas/lpc_assets_loader.dart';
import 'forest_world.dart';
import 'render/camera_framing.dart';
import 'render/render_constants.dart';

class ForestGame extends FlameGame<ForestWorld> {
  final ForestBloc _bloc;
  Offset? _cameraCenter;

  ForestGame({required ForestBloc bloc, LpcAssetsLoader? assetsLoader, math.Random? random})
    : _bloc = bloc,
      super(
        world: ForestWorld(bloc: bloc, assetsLoader: assetsLoader ?? LpcAssetsLoader(), random: random),
      );

  @override
  Color backgroundColor() => const Color(RenderConstants.backgroundColor);

  @override
  Future<void> onLoad() async {
    camera.viewfinder
      ..zoom = RenderConstants.cameraZoom
      ..anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    final frameSeconds = math.min(dt, RenderConstants.maxFrameSeconds);
    _dispatchFrame(frameSeconds);
    super.update(frameSeconds);
    _followPlayer();
  }

  void _dispatchFrame(double frameSeconds) {
    final state = _bloc.state;
    if (state is! ForestSuccess || !world.isReady) return;
    if (state.data.placement != null) {
      final pointer = world.mousePosition(camera);
      if (pointer != null) _bloc.add(ForestPointerMoved(position: pointer));
    }
    _bloc.add(ForestTicked(deltaMs: frameSeconds * 1000));
  }

  void _followPlayer() {
    final data = _bloc.state.data;
    final player = data.player;
    final snapshot = data.world;
    if (player == null || snapshot == null) return;
    final zoom = camera.viewfinder.zoom;
    final target = Offset(player.position.x, player.position.y);
    final previous = _cameraCenter;
    final center = CameraFraming.center(
      current: previous ?? target,
      target: target,
      world: Size(snapshot.width, snapshot.height),
      view: Size(size.x / zoom, size.y / zoom),
      lerp: previous == null ? 1 : RenderConstants.cameraLerp,
    );
    _cameraCenter = center;
    final snapped = CameraFraming.snap(center, zoom);
    camera.viewfinder.position = Vector2(snapped.dx, snapped.dy);
  }
}
