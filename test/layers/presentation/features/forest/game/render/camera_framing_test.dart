import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/camera_framing.dart';

void main() {
  final world = Size(1600, 1200);
  final view = Size(400, 300);

  test('testWhenFollowingWithFullLerpThenCentresOnThePlayer', () {
    // given
    final player = Offset(800, 600);

    // when
    final center = CameraFraming.center(current: Offset.zero, target: player, world: world, view: view, lerp: 1);

    // then
    expect(center, Offset(800, 600));
  });

  test('testWhenThePlayerIsNearACornerThenTheCameraStaysInsideTheWorld', () {
    // given
    final player = Offset(10, 1190);

    // when
    final center = CameraFraming.center(current: player, target: player, world: world, view: view, lerp: 1);

    // then
    expect(center, Offset(200, 1050));
  });

  test('testWhenTheWorldIsSmallerThanTheViewThenItIsCentred', () {
    // given
    final small = Size(300, 200);

    // when
    final center = CameraFraming.center(
      current: Offset.zero,
      target: Offset(10, 10),
      world: small,
      view: view,
      lerp: 1,
    );

    // then
    expect(center, Offset(150, 100));
  });

  test('testWhenLerpingThenMovesATenthOfTheWayEachFrame', () {
    // given
    final current = Offset(800, 600);

    // when
    final center = CameraFraming.center(
      current: current,
      target: Offset(900, 600),
      world: world,
      view: view,
      lerp: 0.1,
    );

    // then
    expect(center.dx, closeTo(810, 1e-9));
    expect(center.dy, closeTo(600, 1e-9));
  });

  test('testWhenSnappingThenRoundsToWholeScreenPixels', () {
    // given
    final center = Offset(10.3, 20.2);

    // when
    final snapped = CameraFraming.snap(center, 2);

    // then
    expect(snapped, Offset(10.5, 20));
  });
}
