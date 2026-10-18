import 'package:farming/layers/data/datasources/level/local/level_local_datasource_impl.dart';
import 'package:farming/layers/data/repositories/level/mappers/building_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/decoration_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/ground_item_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/level_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/position_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/rock_mapper_dbo.dart';
import 'package:farming/layers/data/repositories/level/mappers/tree_mapper_dbo.dart';
import 'package:farming/layers/domain/entities/geometry/position_entity.dart';
import 'package:farming/layers/domain/world/world.dart';

abstract final class LevelScenarioMock {
  static const PositionEntity oldAxeSpot = PositionEntity(x: 856, y: 608);

  static World forest() => LevelMapperDBO(
    positionMapperDBO: PositionMapperDBO(),
    treeMapperDBO: TreeMapperDBO(),
    decorationMapperDBO: DecorationMapperDBO(),
    groundItemMapperDBO: GroundItemMapperDBO(),
    rockMapperDBO: RockMapperDBO(),
    buildingMapperDBO: BuildingMapperDBO(),
  ).toEntity(const LevelLocalDatasourceImpl().fetch());
}
