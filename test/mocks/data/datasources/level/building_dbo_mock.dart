import 'package:farming/layers/data/datasources/level/local/dbo/building_dbo.dart';

abstract final class BuildingDBOMock {
  static const camp = BuildingDBO(id: 'camp', blueprint: 'camp', x: 700, y: 592);
  static const workshop = BuildingDBO(id: 'shop', blueprint: 'workshop', x: 300, y: 200);
  static const withoutId = BuildingDBO(blueprint: 'camp', x: 1, y: 2);
  static const withoutPosition = BuildingDBO(id: 'camp', blueprint: 'camp');
  static const unknownBlueprint = BuildingDBO(id: 'castle-1', blueprint: 'castle', x: 0, y: 0);
  static const withoutBlueprint = BuildingDBO(id: 'nothing', x: 0, y: 0);
}
