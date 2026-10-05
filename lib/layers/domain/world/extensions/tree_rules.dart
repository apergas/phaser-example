import '../../entities/tree/tree_entity.dart';

extension TreeRules on TreeEntity {
  TreeEntity hit() => isFelled ? this : copyWith(hitsTaken: hitsTaken + 1);
}
