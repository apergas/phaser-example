import 'package:rpg/layers/domain/entities/hero/combat_stats_entity.dart';

abstract final class CombatStatsEntityMock {
  static const CombatStatsEntity heroBase = CombatStatsEntity(attack: 4, defense: 1, health: 30);

  static const CombatStatsEntity heroWithShortSwordAndLeather = CombatStatsEntity(attack: 7, defense: 3, health: 40);

  static const CombatStatsEntity heroFullyGeared = CombatStatsEntity(attack: 14, defense: 8, health: 75);

  static const CombatStatsEntity bandit = CombatStatsEntity(attack: 3, defense: 0, health: 20);

  static const CombatStatsEntity brute = CombatStatsEntity(attack: 31, defense: 6, health: 55);
}
