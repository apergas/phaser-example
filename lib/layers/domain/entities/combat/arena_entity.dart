import 'package:collection/collection.dart';

import 'arena_level_status_entity.dart';

class ArenaEntity {
  final int heroPower;
  final List<ArenaLevelStatusEntity> levels;

  const ArenaEntity({required this.heroPower, required this.levels});

  ArenaEntity copyWith({int? heroPower, List<ArenaLevelStatusEntity>? levels}) {
    return ArenaEntity(heroPower: heroPower ?? this.heroPower, levels: levels ?? this.levels);
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaEntity &&
      other.heroPower == heroPower &&
      const ListEquality<ArenaLevelStatusEntity>().equals(other.levels, levels);

  @override
  int get hashCode => Object.hash(heroPower, const ListEquality<ArenaLevelStatusEntity>().hash(levels));
}
