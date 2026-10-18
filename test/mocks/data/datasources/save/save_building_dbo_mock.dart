import 'package:farming/layers/data/datasources/save/local/dbo/save_building_dbo.dart';

abstract final class SaveBuildingDBOMock {
  static const SaveBuildingDBO halfBuilt = SaveBuildingDBO(
    id: 'building-1',
    blueprint: 'house',
    x: 0,
    y: 0,
    hitsDone: 4,
  );
  static const SaveBuildingDBO complete = SaveBuildingDBO(
    id: 'building-1',
    blueprint: 'house',
    x: 0,
    y: 0,
    hitsDone: 8,
  );
  static const SaveBuildingDBO site = SaveBuildingDBO(id: 'building-1', blueprint: 'house', x: 0, y: 0);
  static const SaveBuildingDBO camp = SaveBuildingDBO(id: 'camp', blueprint: 'camp', x: 700, y: 592, hitsDone: 1);
  static const SaveBuildingDBO house = SaveBuildingDBO(id: 'house', blueprint: 'house', x: 300, y: 100, hitsDone: 8);
  static const SaveBuildingDBO finishedHouse = SaveBuildingDBO(
    id: 'building-1',
    blueprint: 'house',
    x: 600,
    y: 300,
    hitsDone: 8,
  );
  static const SaveBuildingDBO forgeSite = SaveBuildingDBO(
    id: 'building-3',
    blueprint: 'forge',
    x: 900,
    y: 300,
    hitsDone: 4,
  );
  static const SaveBuildingDBO storehouse = SaveBuildingDBO(
    id: 'building-2',
    blueprint: 'storehouse',
    x: 750,
    y: 300,
    hitsDone: 8,
  );
  static const SaveBuildingDBO quarrySite = SaveBuildingDBO(
    id: 'building-4',
    blueprint: 'quarry',
    x: 300,
    y: 300,
    hitsDone: 2,
  );
  static const SaveBuildingDBO withTooManyHits = SaveBuildingDBO(
    id: 'building-1',
    blueprint: 'house',
    x: 0,
    y: 0,
    hitsDone: 9,
  );
  static const SaveBuildingDBO withNegativeHits = SaveBuildingDBO(
    id: 'building-1',
    blueprint: 'house',
    x: 0,
    y: 0,
    hitsDone: -1,
  );
  static const SaveBuildingDBO withoutId = SaveBuildingDBO(blueprint: 'house', x: 0, y: 0);
  static const SaveBuildingDBO unknownBlueprint = SaveBuildingDBO(id: 'building-1', blueprint: 'castle', x: 0, y: 0);
  static const SaveBuildingDBO withoutX = SaveBuildingDBO(id: 'building-1', blueprint: 'house', y: 0);
  static const SaveBuildingDBO withoutY = SaveBuildingDBO(id: 'building-1', blueprint: 'house', x: 0);
  static const Map<String, dynamic> wrongTypes = {
    'id': 'building-1',
    'blueprint': 'house',
    'x': 0,
    'y': 0,
    'hitsDone': 'four',
  };
}
