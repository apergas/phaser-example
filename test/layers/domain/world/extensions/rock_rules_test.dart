import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/world/extensions/rock_rules.dart';

import '../../../../mocks/domain/entities/rock/rock_entity_mock.dart';

void main() {
  test('testWhenHittingARockThenItTakesOneMoreHit', () {
    // given
    const rock = RockEntityMock.intact;

    // when
    final hit = rock.hit();

    // then
    expect(hit, RockEntityMock.onceHit);
  });

  test('testWhenHittingABrokenRockThenItDoesNotGoPastItsHits', () {
    // given
    const rock = RockEntityMock.almostBroken;

    // when
    final twice = rock.hit().hit();

    // then
    expect(twice, RockEntityMock.broken);
  });
}
