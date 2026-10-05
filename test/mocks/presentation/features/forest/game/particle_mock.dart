import 'dart:math' as math;

import 'package:rpg/layers/domain/entities/geometry/position_entity.dart';

abstract final class ParticleMock {
  static const PositionEntity trunkBase = PositionEntity(x: 100, y: 120);
  static const PositionEntity chipOrigin = PositionEntity(x: 100, y: 110);
  static const PositionEntity dustOrigin = PositionEntity(x: 200, y: 200);
  static const PositionEntity buildingCenter = PositionEntity(x: 200, y: 180);

  static math.Random get chipsRandom => math.Random(7);
  static math.Random get seededOne => math.Random(1);
  static math.Random get dustRandom => math.Random(3);
}
