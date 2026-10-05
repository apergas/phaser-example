import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/config/constants/enum/decoration_kind.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/level_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/position_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../../mocks/data/datasources/level/level_dbo_mock.dart';

void main() {
  late LevelMapperDBO sut;

  setUp(() {
    sut = LevelMapperDBO(
      positionMapperDBO: PositionMapperDBO(),
      treeMapperDBO: TreeMapperDBO(),
      decorationMapperDBO: DecorationMapperDBO(),
      groundItemMapperDBO: GroundItemMapperDBO(),
    );
  });

  test('testWhenMappingAValidLevelThenBuildsTheWorldWithDomainRules', () {
    // given
    const dbo = LevelDBOMock.mock;

    // when
    final world = sut.toEntity(dbo);

    // then
    expect(world.width, 400.0);
    expect(world.height, 300.0);
    expect(world.player.position, const PositionEntity(x: 200, y: 150));
    expect(world.player.speed, 110.0);
    expect(world.player.radius, 8.0);
    expect(world.trees.single.id, 'tree-a');
    expect(world.trees.single.woodYield, 5);
    expect(world.trees.single.trunkRadius, 12.0);
    expect(world.trees.single.hitsToFell, 5);
    expect(world.trees.single.kind, TreeKind.oak);
    expect(world.items.single.kind, ToolKind.axe);
    expect(world.items.single.position, const PositionEntity(x: 220, y: 150));
    expect(world.decorations.single.kind, DecorationKind.tallGrass);
    expect(world.decorations.single.position, const PositionEntity(x: 300, y: 200));
  });

  test('testWhenMappingTwiceThenEachWorldIsIndependent', () {
    // given
    final first = sut.toEntity(LevelDBOMock.mock);

    // when
    first.movePlayerTo(const PositionEntity(x: 10, y: 10));
    first.advance(1000);
    final second = sut.toEntity(LevelDBOMock.mock);

    // then
    expect(second.player.position, const PositionEntity(x: 200, y: 150));
  });

  test('testWhenLevelHasUnknownItemKindThenThrowsUnknownItemKindException', () {
    // given
    const dbo = LevelDBOMock.mockWithUnknownItem;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(
      map,
      throwsA(isA<UnknownItemKindException>().having((exception) => exception.data, 'data', 'mystery: "laser"')),
    );
  });

  test('testWhenLevelHasUnknownTreeKindThenThrowsUnknownTreeKindException', () {
    // given
    const dbo = LevelDBOMock.mockWithUnknownTreeKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(
      map,
      throwsA(isA<UnknownTreeKindException>().having((exception) => exception.data, 'data', 'tree-x: "palm"')),
    );
  });

  test('testWhenLevelHasUnknownDecorationKindThenThrowsUnknownDecorationKindException', () {
    // given
    const dbo = LevelDBOMock.mockWithUnknownDecorationKind;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(
      map,
      throwsA(
        isA<UnknownDecorationKindException>().having((exception) => exception.data, 'data', 'decoration-x: "lava"'),
      ),
    );
  });

  test('testWhenLevelHasNoSizeThenThrowsInvalidLevelException', () {
    // given
    const dbo = LevelDBOMock.mockWithoutSize;

    // when
    void map() => sut.toEntity(dbo);

    // then
    expect(map, throwsA(isA<InvalidLevelException>().having((exception) => exception.data, 'data', 'missing width')));
  });
}
