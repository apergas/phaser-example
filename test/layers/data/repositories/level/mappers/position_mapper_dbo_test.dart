import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/data/repositories/level/mappers/position_mapper_dbo.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../../mocks/data/datasources/level/point_dbo_mock.dart';

void main() {
  late PositionMapperDBO sut;

  setUp(() {
    sut = PositionMapperDBO();
  });

  test('testWhenPointHasNoCoordinatesThenDefaultsThemToZero', () {
    // given
    const dbo = PointDBOMock.empty;

    // when
    final position = sut.toEntity(dbo);

    // then
    expect(position, const PositionEntity(x: 0, y: 0));
  });

  test('testWhenPointHasCoordinatesThenKeepsThem', () {
    // given
    const dbo = PointDBOMock.playerStart;

    // when
    final position = sut.toEntity(dbo);

    // then
    expect(position, const PositionEntity(x: 800, y: 600));
  });
}
