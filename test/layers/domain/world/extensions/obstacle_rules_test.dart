import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/extensions/obstacle_rules.dart';

import '../../../../mocks/domain/entities/geometry/obstacle_entity_mock.dart';

void main() {
  test('testWhenFootprintsOverlapThenObstacleBlocks', () {
    // given
    const obstacle = ObstacleEntityMock.mock;

    // when
    final blocksNear = obstacle.blocks(const PositionEntity(x: 15, y: 0), 8);
    final blocksFar = obstacle.blocks(const PositionEntity(x: 0, y: 0), 8);

    // then
    expect(blocksNear, isTrue);
    expect(blocksFar, isFalse);
  });
}
