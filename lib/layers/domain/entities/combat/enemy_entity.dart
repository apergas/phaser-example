import '../../../../core/config/constants/enum/enemy_kind.dart';
import '../hero/combat_stats_entity.dart';

class EnemyEntity {
  final EnemyKind kind;
  final CombatStatsEntity stats;

  const EnemyEntity({required this.kind, required this.stats});

  EnemyEntity copyWith({EnemyKind? kind, CombatStatsEntity? stats}) {
    return EnemyEntity(kind: kind ?? this.kind, stats: stats ?? this.stats);
  }

  @override
  bool operator ==(Object other) => other is EnemyEntity && other.kind == kind && other.stats == stats;

  @override
  int get hashCode => Object.hash(kind, stats);
}
