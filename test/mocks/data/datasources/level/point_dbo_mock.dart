import 'package:rpg/layers/data/datasources/level/local/dbo/point_dbo.dart';

abstract final class PointDBOMock {
  static const playerStart = PointDBO(x: 800.0, y: 600.0);
  static const empty = PointDBO();
}
