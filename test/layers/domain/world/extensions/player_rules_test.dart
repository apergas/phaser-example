import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/extensions/player_rules.dart';

import '../../../../mocks/domain/entities/player/player_entity_mock.dart';
import '../../../../mocks/domain/entities/player/activity_entity_mock.dart';
import '../../../../mocks/domain/entities/player/intent_entity_mock.dart';

void main() {
  test('testWhenCreatedThenIsIdleWithoutNextPosition', () {
    // given
    const player = PlayerEntityMock.mock;

    // when
    final next = player.nextPosition(1000);

    // then
    expect(player.activity, ActivityEntityMock.idle);
    expect(next, isNull);
  });

  test('testWhenWalkingThenNextPositionAdvancesSpeedTimesSecondsWithoutMoving', () {
    // given
    final player = PlayerEntityMock.mock
        .copyWith(position: const PositionEntity(x: 0, y: 0))
        .walkTo(const PositionEntity(x: 1000, y: 0));

    // when
    final next = player.nextPosition(500);

    // then
    expect(next, const PositionEntity(x: 50, y: 0));
    expect(player.position, const PositionEntity(x: 0, y: 0));
  });

  test('testWhenStoppingThenReturnsToIdle', () {
    // given
    final walking = PlayerEntityMock.mock.walkTo(const PositionEntity(x: 10, y: 0));

    // when
    final stopped = walking.stop();

    // then
    expect(stopped.isMoving, isFalse);
    expect(stopped.activity, ActivityEntityMock.idle);
  });

  test('testWhenContinuingWorkThenTracksElapsedTime', () {
    // given
    final working = PlayerEntityMock.mock.startWork(IntentEntityMock.chop);

    // when
    final later = working.continueWork(300);

    // then
    expect(later.activity, ActivityEntityMock.makeWorking(elapsedMs: 300));
  });
}
