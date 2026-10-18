import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/building/placement_rule_entity_mock.dart';

void main() {
  test('testWhenComparingNearRockRulesThenTheRangeCounts', () {
    // given
    const rule = PlacementRuleEntityMock.nearRock;

    // when
    final same = rule == PlacementRuleEntityMock.nearRockCopy;
    final otherRange = rule == PlacementRuleEntityMock.veryNearRock;

    // then
    expect(same, isTrue);
    expect(rule.hashCode, PlacementRuleEntityMock.nearRockCopy.hashCode);
    expect(otherRange, isFalse);
  });

  test('testWhenComparingDifferentKindsOfRuleThenTheyAreNotEqual', () {
    // given
    const anywhere = PlacementRuleEntityMock.anywhere;

    // when
    final equal = anywhere == PlacementRuleEntityMock.nearRock;

    // then
    expect(equal, isFalse);
    expect(anywhere, PlacementRuleEntityMock.anywhere);
  });
}
