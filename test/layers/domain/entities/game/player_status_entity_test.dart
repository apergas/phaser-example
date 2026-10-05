import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/player_activity.dart';
import 'package:rpg/layers/domain/entities/game/player_status_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../mocks/domain/entities/game/player_status_entity_mock.dart';

void main() {
  test('testWhenTargetsDifferThenStatusesAreNotEqual', () {
    // given
    const status = PlayerStatusEntityMock.mock;

    // when
    final sameStatus =
        status ==
        const PlayerStatusEntity(
          position: PositionEntity(x: 100, y: 100),
          activity: PlayerActivity.idle,
          swingProgress: 0,
          wood: 0,
          hasAxe: false,
        );
    final withTarget =
        status ==
        const PlayerStatusEntity(
          position: PositionEntity(x: 100, y: 100),
          activity: PlayerActivity.idle,
          target: PositionEntity(x: 1, y: 1),
          swingProgress: 0,
          wood: 0,
          hasAxe: false,
        );

    // then
    expect(sameStatus, isTrue);
    expect(withTarget, isFalse);
  });
}
