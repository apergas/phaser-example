import 'combat_stats_entity.dart';
import 'hero_entity.dart';

class HeroStatusEntity {
  final HeroEntity hero;
  final CombatStatsEntity stats;
  final int power;

  const HeroStatusEntity({required this.hero, required this.stats, required this.power});

  HeroStatusEntity copyWith({HeroEntity? hero, CombatStatsEntity? stats, int? power}) {
    return HeroStatusEntity(hero: hero ?? this.hero, stats: stats ?? this.stats, power: power ?? this.power);
  }

  @override
  bool operator ==(Object other) =>
      other is HeroStatusEntity && other.hero == hero && other.stats == stats && other.power == power;

  @override
  int get hashCode => Object.hash(hero, stats, power);
}
