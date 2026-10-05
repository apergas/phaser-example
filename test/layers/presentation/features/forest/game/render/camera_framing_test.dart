import 'package:flame/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/presentation/features/forest/game/render/camera_framing.dart';

void main() {
  final world = Vector2(1600, 1200);
  final view = Vector2(400, 300);

  test('testWhenFollowingWithFullLerpThenCentresOnThePlayer', () {
    // given
    final player = Vector2(800, 600);

    // when
    final center = CameraFraming.center(current: Vector2.zero(), target: player, world: world, view: view, lerp: 1);

    // then
    expect(center, Vector2(800, 600));
  });

  test('testWhenThePlayerIsNearACornerThenTheCameraStaysInsideTheWorld', () {
    // given
    final player = Vector2(10, 1190);

    // when
    final center = CameraFraming.center(current: player, target: player, world: world, view: view, lerp: 1);

    // then
    expect(center, Vector2(200, 1050));
  });

  test('testWhenTheWorldIsSmallerThanTheViewThenItIsCentred', () {
    // given
    final small = Vector2(300, 200);

    // when
    final center = CameraFraming.center(
      current: Vector2.zero(),
      target: Vector2(10, 10),
      world: small,
      view: view,
      lerp: 1,
    );

    // then
    expect(center, Vector2(150, 100));
  });

  test('testWhenLerpingThenMovesATenthOfTheWayEachFrame', () {
    // given
    final current = Vector2(800, 600);

    // when
    final center = CameraFraming.center(
      current: current,
      target: Vector2(900, 600),
      world: world,
      view: view,
      lerp: 0.1,
    );

    // then
    expect(center.x, closeTo(810, 1e-9));
    expect(center.y, closeTo(600, 1e-9));
  });

  test('testWhenSnappingThenRoundsToWholeScreenPixels', () {
    // given
    final center = Vector2(10.3, 20.2);

    // when
    final snapped = CameraFraming.snap(center, 2);

    // then
    expect(snapped, Vector2(10.5, 20));
  });
}
