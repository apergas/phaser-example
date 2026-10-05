import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rpg/core/config/constants/enum/tree_kind.dart';
import 'package:rpg/core/error-handling/exceptions/app_exceptions.dart';
import 'package:rpg/core/error-handling/handlers/app_exception_handler.dart';
import 'package:rpg/layers/data/datasources/level/source/level_local_datasource.dart';
import 'package:rpg/layers/data/repositories/level/level_repository_impl.dart';
import 'package:rpg/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/level_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/position_mapper_dbo.dart';
import 'package:rpg/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';
import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

import '../../../../mocks/data/datasources/level/level_dbo_mock.dart';
import 'level_repository_impl_test.mocks.dart';

@GenerateMocks([LevelLocalDatasource])
void main() {
  late MockLevelLocalDatasource localDatasource;
  late LevelRepositoryImpl sut;

  setUp(() {
    localDatasource = MockLevelLocalDatasource();
    sut = LevelRepositoryImpl(
      localDatasource: localDatasource,
      levelMapperDBO: LevelMapperDBO(
        positionMapperDBO: PositionMapperDBO(),
        treeMapperDBO: TreeMapperDBO(),
        decorationMapperDBO: DecorationMapperDBO(),
        groundItemMapperDBO: GroundItemMapperDBO(),
      ),
      appExceptionHandler: AppExceptionHandler(),
    );
  });

  test('testWhenLoadWithSuccessThenBuildsTheWorldFromTheDatasource', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mock);

    // when
    final world = sut.load();

    // then
    verify(localDatasource.fetch()).called(1);
    expect(world.width, 400.0);
    expect(world.player.position, const PositionEntity(x: 200, y: 150));
    expect(world.trees.single.kind, TreeKind.oak);
  });

  test('testWhenLoadTwiceThenEachWorldIsIndependent', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mock);
    final first = sut.load();

    // when
    first.movePlayerTo(const PositionEntity(x: 10, y: 10));
    first.advance(1000);
    final second = sut.load();

    // then
    expect(second.player.position, const PositionEntity(x: 200, y: 150));
  });

  test('testWhenLevelHasUnknownItemKindThenThrowsUnknownItemKindException', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mockWithUnknownItem);

    // when
    void load() => sut.load();

    // then
    expect(
      load,
      throwsA(isA<UnknownItemKindException>().having((exception) => exception.data, 'data', 'mystery: "laser"')),
    );
  });

  test('testWhenLevelHasUnknownTreeKindThenThrowsUnknownTreeKindException', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mockWithUnknownTreeKind);

    // when
    void load() => sut.load();

    // then
    expect(
      load,
      throwsA(isA<UnknownTreeKindException>().having((exception) => exception.data, 'data', 'tree-x: "palm"')),
    );
  });

  test('testWhenLevelHasNoSizeThenThrowsInvalidLevelException', () {
    // given
    when(localDatasource.fetch()).thenReturn(LevelDBOMock.mockWithoutSize);

    // when
    void load() => sut.load();

    // then
    expect(load, throwsA(isA<InvalidLevelException>()));
  });

  test('testWhenDatasourceFailsThenErrorIsRoutedThroughTheHandler', () {
    // given
    when(localDatasource.fetch()).thenThrow(StateError('disk unavailable'));

    // when
    void load() => sut.load();

    // then
    expect(load, throwsA(isA<GenericException>()));
    verify(localDatasource.fetch()).called(1);
  });
}
