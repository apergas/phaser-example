import 'combat_stats_entity.dart';
import 'hero_entity.dart';

class HeroStatusEntity {
  final HeroEntity hero;
  final CombatStatsEntity stats;
  final int power;
  final bool isChampion;

  const HeroStatusEntity({required this.hero, required this.stats, required this.power, required this.isChampion});

  HeroStatusEntity copyWith({HeroEntity? hero, CombatStatsEntity? stats, int? power, bool? isChampion}) {
    return HeroStatusEntity(
      hero: hero ?? this.hero,
      stats: stats ?? this.stats,
      power: power ?? this.power,
      isChampion: isChampion ?? this.isChampion,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HeroStatusEntity &&
      other.hero == hero &&
      other.stats == stats &&
      other.power == power &&
      other.isChampion == isChampion;

  @override
  int get hashCode => Object.hash(hero, stats, power, isChampion);
}
