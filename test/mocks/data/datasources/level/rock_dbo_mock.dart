import 'package:farming/layers/data/datasources/level/local/dbo/rock_dbo.dart';

abstract final class RockDBOMock {
  static const firstGenerated = RockDBO(id: 'rock-1', x: 303.6648352164775, y: 1110.241115950048);
  static const secondGenerated = RockDBO(id: 'rock-2', x: 1333.0966523010284, y: 464.6730585023761);
  static const thirdGenerated = RockDBO(id: 'rock-3', x: 385.6782182957977, y: 823.0706523545086);
  static const firstGeneratedRocks = [firstGenerated, secondGenerated, thirdGenerated];
  static const mock = RockDBO(id: 'rock-a', x: 120, y: 80);
  static const withoutId = RockDBO(x: 5, y: 6);
  static const withoutPosition = RockDBO(id: 'rock-b');
}
