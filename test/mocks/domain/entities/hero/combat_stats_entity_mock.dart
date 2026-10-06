import 'package:rpg/layers/domain/entities/hero/combat_stats_entity.dart';

abstract final class CombatStatsEntityMock {
  static const CombatStatsEntity heroBase = CombatStatsEntity(attack: 4, defense: 1, health: 30);

  static const CombatStatsEntity heroWithShortSwordAndLeather = CombatStatsEntity(attack: 7, defense: 3, health: 40);

  static const CombatStatsEntity heroFullyGeared = CombatStatsEntity(attack: 14, defense: 8, health: 75);

  static const CombatStatsEntity bandit = CombatStatsEntity(attack: 3, defense: 0, health: 20);

  static const CombatStatsEntity brute = CombatStatsEntity(attack: 31, defense: 6, health: 55);

  static const CombatStatsEntity veteranBandit = CombatStatsEntity(attack: 6, defense: 2, health: 30);

  static const CombatStatsEntity barbarianGuard = CombatStatsEntity(attack: 6, defense: 2, health: 30);

  static const CombatStatsEntity barbarianChief = CombatStatsEntity(attack: 12, defense: 5, health: 70);

  static const CombatStatsEntity duelist = CombatStatsEntity(attack: 8, defense: 0, health: 24);

  static const CombatStatsEntity wall = CombatStatsEntity(attack: 2, defense: 20, health: 100);
}
