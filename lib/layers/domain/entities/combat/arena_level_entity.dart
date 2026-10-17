import 'package:collection/collection.dart';

import '../../../../core/config/constants/enum/arena_level_id.dart';
import '../../../../core/config/constants/enum/resource.dart';
import 'enemy_entity.dart';

class ArenaLevelEntity {
  final ArenaLevelId id;
  final List<EnemyEntity> enemies;
  final Map<Resource, int> reward;
  final double enemySkillChance;

  const ArenaLevelEntity({required this.id, required this.enemies, required this.reward, this.enemySkillChance = 0})
    : assert(enemySkillChance >= 0 && enemySkillChance <= 1);

  int get power => enemies.fold(0, (sum, enemy) => sum + enemy.stats.power);

  ArenaLevelEntity copyWith({
    ArenaLevelId? id,
    List<EnemyEntity>? enemies,
    Map<Resource, int>? reward,
    double? enemySkillChance,
  }) {
    return ArenaLevelEntity(
      id: id ?? this.id,
      enemies: enemies ?? this.enemies,
      reward: reward ?? this.reward,
      enemySkillChance: enemySkillChance ?? this.enemySkillChance,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ArenaLevelEntity &&
      other.id == id &&
      const ListEquality<EnemyEntity>().equals(other.enemies, enemies) &&
      const MapEquality<Resource, int>().equals(other.reward, reward) &&
      other.enemySkillChance == enemySkillChance;

  @override
  int get hashCode => Object.hash(
    id,
    const ListEquality<EnemyEntity>().hash(enemies),
    const MapEquality<Resource, int>().hash(reward),
    enemySkillChance,
  );
}
