import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;

import '../../../../domain/entities/geometry/position_entity.dart';
import '../bloc/forest_bloc.dart';
import 'atlas/lpc_assets_loader.dart';
import 'forest_scene_component.dart';
import 'forest_state_listener.dart';
import 'render/position_conversion.dart';

class ForestWorld extends World with TapCallbacks, SecondaryTapCallbacks, PointerMoveCallbacks, DragCallbacks {
  final ForestBloc _bloc;
  final LpcAssetsLoader _assetsLoader;
  final math.Random? _random;
  ForestSceneComponent? _scene;
  Vector2? _mouseCanvasPosition;
  PointerDeviceKind _dragDeviceKind = PointerDeviceKind.unknown;

  ForestWorld({required this._bloc, required this._assetsLoader, this._random});

  ForestSceneComponent? get scene => _scene;

  bool get isReady => _scene != null;

  @override
  Future<void> onLoad() async {
    final scene = ForestSceneComponent(assets: await _assetsLoader.load(), random: _random);
    await add(
      FlameBlocProvider<ForestBloc, ForestState>.value(
        value: _bloc,
        children: [
          scene,
          ForestStateListener(scene: scene),
        ],
      ),
    );
    _scene = scene;
  }

  void clickAt(Vector2 point, {required bool isMouse, bool isSecondary = false}) {
    final scene = _scene;
    final state = _bloc.state;
    if (scene == null || state is! ForestSuccess) return;
    final position = point.toPositionEntity();
    if (!isMouse && !isSecondary && state.data.placement != null) {
      _bloc.add(ForestPointerMoved(position: position));
      return;
    }
    _bloc.add(ForestMapClicked(position: position, treeId: scene.treeAt(point), isSecondary: isSecondary));
  }

  void mouseMovedTo(Vector2 canvasPosition) {
    _mouseCanvasPosition = canvasPosition.clone();
  }

  void dragTo(Vector2 point) {
    final state = _bloc.state;
    if (state is! ForestSuccess || state.data.placement == null) return;
    _bloc.add(ForestPointerMoved(position: point.toPositionEntity()));
  }

  PositionEntity? mousePosition(CameraComponent camera) {
    final canvasPosition = _mouseCanvasPosition;
    if (canvasPosition == null) return null;
    return camera.globalToLocal(canvasPosition).toPositionEntity();
  }

  @override
  void onTapDown(TapDownEvent event) {
    clickAt(event.localPosition, isMouse: event.deviceKind == PointerDeviceKind.mouse);
  }

  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    clickAt(event.localPosition, isMouse: true, isSecondary: true);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    if (event.raw.kind == PointerDeviceKind.mouse) mouseMovedTo(event.canvasPosition);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragDeviceKind = event.deviceKind;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    if (_dragDeviceKind == PointerDeviceKind.mouse) {
      mouseMovedTo(event.canvasEndPosition);
    } else {
      dragTo(event.localEndPosition);
    }
  }
}
