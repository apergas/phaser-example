import '../../entities/rock/rock_entity.dart';

extension RockRules on RockEntity {
  RockEntity hit() => isBroken ? this : copyWith(hitsTaken: hitsTaken + 1);
}
