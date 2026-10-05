import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/player_activity.dart';
import 'package:rpg/layers/domain/world/extensions/activity_rules.dart';

import '../../../../mocks/domain/entities/player/activity_entity_mock.dart';
import '../../../../mocks/domain/entities/player/intent_entity_mock.dart';

void main() {
  test('testWhenActivityIsIdleThenPlayerActivityIsIdle', () {
    // given
    const activity = ActivityEntityMock.idle;

    // when
    final playerActivity = activity.playerActivity;

    // then
    expect(playerActivity, PlayerActivity.idle);
  });

  test('testWhenActivityIsWalkingThenPlayerActivityIsWalking', () {
    // given
    const activity = ActivityEntityMock.walkingToChop;

    // when
    final playerActivity = activity.playerActivity;

    // then
    expect(playerActivity, PlayerActivity.walking);
  });

  test('testWhenActivityIsChoppingThenPlayerActivityIsChopping', () {
    // given
    final activity = ActivityEntityMock.makeWorking(intent: IntentEntityMock.chop);

    // when
    final playerActivity = activity.playerActivity;

    // then
    expect(playerActivity, PlayerActivity.chopping);
  });

  test('testWhenActivityIsConstructingThenPlayerActivityIsConstructing', () {
    // given
    final activity = ActivityEntityMock.makeWorking(intent: IntentEntityMock.construct);

    // when
    final playerActivity = activity.playerActivity;

    // then
    expect(playerActivity, PlayerActivity.constructing);
  });
}
