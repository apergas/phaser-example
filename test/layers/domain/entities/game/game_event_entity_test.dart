import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';

import '../../../../mocks/domain/entities/game/game_event_entity_mock.dart';

void main() {
  test('testWhenComparingEventsWithSameValuesThenTheyAreEqual', () {
    // given
    const events = GameEventEntityMock.all;

    // when
    final copies = GameEventEntityMock.makeAll();

    // then
    expect(copies, events);
    expect(copies.map((event) => event.hashCode), events.map((event) => event.hashCode));
  });

  test('testWhenEventValuesDifferThenTheyAreNotEqual', () {
    // given
    const felled = GameEventEntityMock.treeFelled;

    // when
    final isEqual = felled == GameEventEntityMock.makeTreeFelled(wood: 5);

    // then
    expect(isEqual, isFalse);
  });

  test('testWhenEventsAreOfDifferentTypesThenTheyAreNotEqual', () {
    // given
    const GameEventEntity hit = GameEventEntityMock.treeHit;

    // when
    final isEqual = hit == GameEventEntityMock.treeFelled;

    // then
    expect(isEqual, isFalse);
  });
}
