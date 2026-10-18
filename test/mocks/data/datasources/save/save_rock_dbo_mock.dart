import 'package:farming/layers/data/datasources/save/local/dbo/save_rock_dbo.dart';

abstract final class SaveRockDBOMock {
  static const SaveRockDBO onceHit = SaveRockDBO(id: 'rock-1', x: 300, y: 100, hitsTaken: 1);
  static const SaveRockDBO intact = SaveRockDBO(id: 'rock-1', x: 300, y: 100);
  static const SaveRockDBO almostBroken = SaveRockDBO(id: 'rock-1', x: 300, y: 100, hitsTaken: 7);
  static const SaveRockDBO broken = SaveRockDBO(id: 'rock-1', x: 300, y: 100, hitsTaken: 8);
  static const SaveRockDBO withNegativeHits = SaveRockDBO(id: 'rock-1', x: 300, y: 100, hitsTaken: -1);
  static const SaveRockDBO withoutId = SaveRockDBO(x: 300, y: 100);
  static const SaveRockDBO withoutX = SaveRockDBO(id: 'rock-1', y: 100);
  static const SaveRockDBO withoutY = SaveRockDBO(id: 'rock-1', x: 300);
  static const Map<String, dynamic> wrongTypes = {'id': 'rock-1', 'x': 300, 'y': 100, 'hitsTaken': 1.5};
}
