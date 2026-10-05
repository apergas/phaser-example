import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/layers/domain/entities/game/game_event_entity.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';
import 'package:rpg/layers/domain/world/extensions/inventory_rules.dart';

import '../../../mocks/domain/entities/item/ground_item_entity_mock.dart';
import '../../../mocks/domain/world/world_mock.dart';

void main() {
  test('testWhenPlayerWalksOverAToolThenPicksItUp', () {
    // given
    final world = WorldMock.make(items: [GroundItemEntityMock.mock]);
    world.movePlayerTo(const PositionEntity(x: 160, y: 100));

    // when
    final events = world.advanceFor(1000);

    // then
    expect(events, contains(const ItemPickedUpEventEntity(itemId: 'axe-1', kind: ToolKind.axe)));
    expect(world.player.inventory.hasTool(ToolKind.axe), isTrue);
    expect(world.items, isEmpty);
  });
}
