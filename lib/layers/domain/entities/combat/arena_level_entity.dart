import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/resource.dart';
import 'enemy_entity.dart';

class ArenaLevelEntity {
  final ArenaLevelId id;
  final List<EnemyEntity> enemies;
  final Map<Resource, int> reward;

  const ArenaLevelEntity({required this.id, required this.enemies, required this.reward});

  int get power => enemies.fold(0, (sum, enemy) => sum + enemy.stats.power);

  ArenaLevelEntity copyWith({ArenaLevelId? id, List<EnemyEntity>? enemies, Map<Resource, int>? reward}) {
    return ArenaLevelEntity(id: id ?? this.id, enemies: enemies ?? this.enemies, reward: reward ?? this.reward);
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaLevelEntity &&
      other.id == id &&
      const ListEquality<EnemyEntity>().equals(other.enemies, enemies) &&
      const MapEquality<Resource, int>().equals(other.reward, reward);

  @override
  int get hashCode => Object.hash(
    id,
    const ListEquality<EnemyEntity>().hash(enemies),
    const MapEquality<Resource, int>().hash(reward),
  );
}
