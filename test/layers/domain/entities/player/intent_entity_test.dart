import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/player/intent_entity.dart';

import '../../../../mocks/domain/entities/player/intent_entity_mock.dart';

void main() {
  test('testWhenComparingIntentsWithSameValuesThenTheyAreEqual', () {
    // given
    const chop = IntentEntityMock.chop;
    const construct = IntentEntityMock.construct;

    // when
    final chopCopy = IntentEntityMock.makeChop();
    final constructCopy = IntentEntityMock.makeConstruct();

    // then
    expect(chopCopy, chop);
    expect(chopCopy.hashCode, chop.hashCode);
    expect(constructCopy, construct);
    expect(constructCopy.hashCode, construct.hashCode);
  });

  test('testWhenIntentValuesDifferThenTheyAreNotEqual', () {
    // given
    const chop = IntentEntityMock.chop;
    const construct = IntentEntityMock.construct;

    // when
    final otherTree = chop == IntentEntityMock.makeChop(treeId: 'tree-2');
    final otherBuilding = construct == IntentEntityMock.makeConstruct(buildingId: 'building-2');

    // then
    expect(otherTree, isFalse);
    expect(otherBuilding, isFalse);
  });

  test('testWhenIntentsAreOfDifferentTypesThenTheyAreNotEqual', () {
    // given
    const IntentEntity chop = IntentEntityMock.chop;

    // when
    final isEqual = chop == IntentEntityMock.construct;

    // then
    expect(isEqual, isFalse);
  });
}
