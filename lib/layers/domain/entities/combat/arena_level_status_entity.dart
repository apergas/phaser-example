import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/resource.dart';
import 'arena_level_entity.dart';

class ArenaLevelStatusEntity {
  final ArenaLevelEntity level;
  final bool isUnlocked;
  final bool isCleared;
  final Map<Resource, int> nextReward;

  const ArenaLevelStatusEntity({
    required this.level,
    required this.isUnlocked,
    required this.isCleared,
    required this.nextReward,
  });

  ArenaLevelStatusEntity copyWith({
    ArenaLevelEntity? level,
    bool? isUnlocked,
    bool? isCleared,
    Map<Resource, int>? nextReward,
  }) {
    return ArenaLevelStatusEntity(
      level: level ?? this.level,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCleared: isCleared ?? this.isCleared,
      nextReward: nextReward ?? this.nextReward,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaLevelStatusEntity &&
      other.level == level &&
      other.isUnlocked == isUnlocked &&
      other.isCleared == isCleared &&
      const MapEquality<Resource, int>().equals(other.nextReward, nextReward);

  @override
  int get hashCode => Object.hash(level, isUnlocked, isCleared, const MapEquality<Resource, int>().hash(nextReward));
}
