import 'package:rpg/layers/domain/entities/hero/combat_stats_entity.dart';

abstract final class CombatStatsEntityMock {
  static const CombatStatsEntity heroBase = CombatStatsEntity(attackMin: 3, attackMax: 5, defense: 1, health: 30);

  static const CombatStatsEntity heroWithShortSwordAndLeather = CombatStatsEntity(
    attackMin: 6,
    attackMax: 8,
    defense: 3,
    health: 40,
  );

  static const CombatStatsEntity heroFullyGeared = CombatStatsEntity(
    attackMin: 12,
    attackMax: 16,
    defense: 8,
    health: 75,
  );

  static const CombatStatsEntity bandit = CombatStatsEntity(attackMin: 2, attackMax: 4, defense: 0, health: 20);

  static const CombatStatsEntity brute = CombatStatsEntity(attackMin: 30, attackMax: 32, defense: 6, health: 55);

  static const CombatStatsEntity veteranBandit = CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30);

  static const CombatStatsEntity barbarianGuard = CombatStatsEntity(attackMin: 5, attackMax: 7, defense: 2, health: 30);

  static const CombatStatsEntity barbarianChief = CombatStatsEntity(
    attackMin: 10,
    attackMax: 14,
    defense: 5,
    health: 70,
  );

  static const CombatStatsEntity duelist = CombatStatsEntity(attackMin: 7, attackMax: 9, defense: 0, health: 24);

  static const CombatStatsEntity wall = CombatStatsEntity(attackMin: 1, attackMax: 3, defense: 20, health: 100);

  static const CombatStatsEntity heroWithShortSword = CombatStatsEntity(
    attackMin: 6,
    attackMax: 8,
    defense: 1,
    health: 30,
  );
}
