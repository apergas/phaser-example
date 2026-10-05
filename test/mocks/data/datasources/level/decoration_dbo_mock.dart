import 'package:rpg/layers/data/datasources/level/local/dbo/decoration_dbo.dart';

abstract final class DecorationDBOMock {
  static const withoutId = DecorationDBO(kind: 'mushrooms', x: 1, y: 2);
}
