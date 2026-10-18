import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/domain/entities/rock/rock_entity.dart';

import '../../../../mocks/domain/entities/geometry/obstacle_entity_mock.dart';
import '../../../../mocks/domain/entities/rock/rock_entity_mock.dart';

void main() {
  test('testWhenTheRockIsIntactThenAllItsHitsRemainAndItIsNotBroken', () {
    // given
    const rock = RockEntityMock.intact;

    // when
    final state = (rock.hitsRemaining, rock.isBroken);

    // then
    expect(state, (8, false));
  });

  test('testWhenTheRockTookEveryHitThenItIsBroken', () {
    // given
    const rock = RockEntityMock.broken;

    // when
    final state = (rock.hitsRemaining, rock.isBroken);

    // then
    expect(state, (0, true));
  });

  test('testWhenAskingForTheFootprintThenItIsTheRockPositionAndRadius', () {
    // given
    const rock = RockEntityMock.intact;

    // when
    final footprint = rock.footprint;

    // then
    expect(footprint, ObstacleEntityMock.rock);
  });

  test('testWhenCopyingWithHitsThenTheRestIsKept', () {
    // given
    const rock = RockEntityMock.intact;

    // when
    final copy = rock.copyWith(hitsTaken: 7);

    // then
    expect(copy, RockEntityMock.almostBroken);
    expect(copy.hashCode, RockEntityMock.almostBroken.hashCode);
    expect(rock == copy, isFalse);
  });

  test('testWhenTheValuesAreOutOfRangeThenItAsserts', () {
    // given
    const rock = RockEntityMock.intact;

    // when
    RockEntity tooManyHits() => rock.copyWith(hitsTaken: 9);
    RockEntity noRadius() => rock.copyWith(radius: 0);
    RockEntity noHits() => rock.copyWith(hitsToBreak: 0);
    RockEntity negativeStone() => rock.copyWith(stoneYield: -1);

    // then
    for (final build in [tooManyHits, noRadius, noHits, negativeStone]) {
      expect(build, throwsA(isA<AssertionError>()));
    }
  });
}
