import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/repositories/save/mappers/save_position_mapper_dbo.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';

import '../../../../../mocks/data/repositories/save/invalid_save_matcher.dart';

void main() {
  late SavePositionMapperDBO sut;

  setUp(() {
    sut = SavePositionMapperDBO();
  });

  test('testWhenBothCoordinatesArePresentThenItBuildsThePosition', () {
    // given
    const x = 12.5;
    const y = 7.0;

    // when
    final position = sut.toEntity(x: x, y: y, owner: 'tree tree-1');

    // then
    expect(position, const PositionEntity(x: 12.5, y: 7));
  });

  test('testWhenXIsMissingThenItThrowsNamingTheOwner', () {
    // given
    const y = 7.0;

    // when
    void map() => sut.toEntity(x: null, y: y, owner: 'tree tree-1');

    // then
    expect(map, throwsInvalidSave('tree tree-1 without x'));
  });

  test('testWhenYIsMissingThenItThrowsNamingTheOwner', () {
    // given
    const x = 7.0;

    // when
    void map() => sut.toEntity(x: x, y: null, owner: 'rock rock-1');

    // then
    expect(map, throwsInvalidSave('rock rock-1 without y'));
  });
}
