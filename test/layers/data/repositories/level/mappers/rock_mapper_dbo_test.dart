import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/level/mappers/rock_mapper_dbo.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/rules/rules.dart';

import '../../../../../mocks/data/datasources/level/rock_dbo_mock.dart';

void main() {
  late RockMapperDBO sut;

  setUp(() {
    sut = RockMapperDBO();
  });

  test('testWhenMappingARockThenItsSizeStoneAndHitsComeFromTheRules', () {
    // given
    const dbo = RockDBOMock.mock;

    // when
    final rock = sut.toEntity(dbo, index: 0);

    // then
    expect((rock.id, rock.position), ('rock-a', const PositionEntity(x: 120, y: 80)));
    expect(
      (rock.radius, rock.stoneYield, rock.hitsToBreak, rock.hitsTaken),
      (
        Rules.rockRadius,
        Rules.rockStoneYield,
        Rules.rockHitsToBreak,
        0,
      ),
    );
  });

  test('testWhenTheRockHasNoIdThenUsesItsPositionInTheList', () {
    // given
    const dbo = RockDBOMock.withoutId;

    // when
    final rock = sut.toEntity(dbo, index: 2);

    // then
    expect(rock.id, 'rock-3');
  });

  test('testWhenTheRockHasNoPositionThenItIsAtTheOrigin', () {
    // given
    const dbo = RockDBOMock.withoutPosition;

    // when
    final rock = sut.toEntity(dbo, index: 0);

    // then
    expect(rock.position, const PositionEntity(x: 0, y: 0));
  });
}
