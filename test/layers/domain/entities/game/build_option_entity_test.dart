import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/domain/entities/game/build_option_entity_mock.dart';

void main() {
  test('testWhenComparingBuildOptionsThenAffordabilityMatters', () {
    // given
    const option = BuildOptionEntityMock.mock;

    // when
    final isEqual = option == BuildOptionEntityMock.make();
    final notAffordable = option == BuildOptionEntityMock.make(isAffordable: false);

    // then
    expect(isEqual, isTrue);
    expect(notAffordable, isFalse);
  });
}
