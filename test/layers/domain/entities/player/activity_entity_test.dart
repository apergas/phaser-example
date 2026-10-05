import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/player/activity_entity.dart';

import '../../../../mocks/domain/entities/player/activity_entity_mock.dart';
import '../../../../mocks/domain/entities/player/intent_entity_mock.dart';

void main() {
  test('testWhenComparingIdleActivitiesThenTheyAreEqual', () {
    // given
    const idle = ActivityEntityMock.idle;

    // when
    final copy = ActivityEntityMock.makeIdle();

    // then
    expect(copy, idle);
    expect(copy.hashCode, idle.hashCode);
  });

  test('testWhenComparingWalkingActivitiesThenDestinationAndIntentMatter', () {
    // given
    const walking = ActivityEntityMock.walking;

    // when
    final copy = ActivityEntityMock.makeWalking();
    final otherDestination = walking == ActivityEntityMock.makeWalking(x: 51);
    final withIntent = walking == ActivityEntityMock.walkingToChop;
    final sameWithIntent =
        ActivityEntityMock.walkingToChop == ActivityEntityMock.makeWalking(intent: IntentEntityMock.chop);

    // then
    expect(copy, walking);
    expect(copy.hashCode, walking.hashCode);
    expect(otherDestination, isFalse);
    expect(withIntent, isFalse);
    expect(sameWithIntent, isTrue);
  });

  test('testWhenComparingWorkingActivitiesThenIntentAndElapsedTimeMatter', () {
    // given
    const working = ActivityEntityMock.working;

    // when
    final copy = ActivityEntityMock.makeWorking();
    final otherElapsed = working == ActivityEntityMock.makeWorking(elapsedMs: 200);
    final otherIntent = working == ActivityEntityMock.makeWorking(intent: IntentEntityMock.construct);

    // then
    expect(copy, working);
    expect(copy.hashCode, working.hashCode);
    expect(otherElapsed, isFalse);
    expect(otherIntent, isFalse);
  });

  test('testWhenCopyingWorkingActivityWithElapsedTimeThenIntentIsKept', () {
    // given
    const working = ActivityEntityMock.working;

    // when
    final copy = working.copyWith(elapsedMs: 300);

    // then
    expect(copy, ActivityEntityMock.makeWorking(elapsedMs: 300));
  });

  test('testWhenActivitiesAreOfDifferentTypesThenTheyAreNotEqual', () {
    // given
    const ActivityEntity idle = ActivityEntityMock.idle;

    // when
    final isEqual = idle == ActivityEntityMock.walking;

    // then
    expect(isEqual, isFalse);
  });
}
