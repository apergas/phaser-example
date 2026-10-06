import 'package:rpg/core/config/constants/enum/fight_action.dart';
import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/layers/domain/entities/combat/fight_turn_entity.dart';

abstract final class FightTurnEntityMock {
  static FightTurnEntity heroHits({required int round, required int damage, required int enemyHealthAfter}) =>
      FightTurnEntity(
        round: round,
        actor: FightSide.hero,
        actorIndex: 0,
        target: FightSide.enemy,
        targetIndex: 0,
        action: FightAction.hit,
        damage: damage,
        targetHealthAfter: enemyHealthAfter,
      );

  static FightTurnEntity enemyHits({required int round, required int damage, required int heroHealthAfter}) =>
      FightTurnEntity(
        round: round,
        actor: FightSide.enemy,
        actorIndex: 0,
        target: FightSide.hero,
        targetIndex: 0,
        action: FightAction.hit,
        damage: damage,
        targetHealthAfter: heroHealthAfter,
      );

  static List<FightTurnEntity> victoryOverBandit() => [
    heroHits(round: 1, damage: 4, enemyHealthAfter: 16),
    enemyHits(round: 1, damage: 2, heroHealthAfter: 28),
    heroHits(round: 2, damage: 4, enemyHealthAfter: 12),
    enemyHits(round: 2, damage: 2, heroHealthAfter: 26),
    heroHits(round: 3, damage: 4, enemyHealthAfter: 8),
    enemyHits(round: 3, damage: 2, heroHealthAfter: 24),
    heroHits(round: 4, damage: 4, enemyHealthAfter: 4),
    enemyHits(round: 4, damage: 2, heroHealthAfter: 22),
    heroHits(round: 5, damage: 4, enemyHealthAfter: 0),
  ];

  static List<FightTurnEntity> defeatByBrute() => [
    heroHits(round: 1, damage: 1, enemyHealthAfter: 54),
    enemyHits(round: 1, damage: 30, heroHealthAfter: 0),
  ];

  static List<FightTurnEntity> allActions() => [
    heroHits(round: 1, damage: 4, enemyHealthAfter: 16),
    const FightTurnEntity(
      round: 1,
      actor: FightSide.enemy,
      actorIndex: 0,
      target: FightSide.hero,
      targetIndex: 0,
      action: FightAction.dodge,
      damage: 0,
      targetHealthAfter: 30,
    ),
    heroHits(round: 2, damage: 4, enemyHealthAfter: 12),
    enemyHits(round: 2, damage: 22, heroHealthAfter: 8),
    const FightTurnEntity(
      round: 2,
      actor: FightSide.hero,
      actorIndex: 0,
      target: FightSide.hero,
      targetIndex: 0,
      action: FightAction.secondWind,
      damage: 0,
      targetHealthAfter: 20,
    ),
    heroHits(round: 3, damage: 4, enemyHealthAfter: 8),
    const FightTurnEntity(
      round: 3,
      actor: FightSide.hero,
      actorIndex: 0,
      target: FightSide.enemy,
      targetIndex: 0,
      action: FightAction.doubleStrike,
      damage: 4,
      targetHealthAfter: 4,
    ),
    enemyHits(round: 3, damage: 2, heroHealthAfter: 18),
    heroHits(round: 4, damage: 4, enemyHealthAfter: 0),
  ];

  static List<FightTurnEntity> almostBeatDuelist() => [
    heroHits(round: 1, damage: 4, enemyHealthAfter: 20),
    enemyHits(round: 1, damage: 7, heroHealthAfter: 23),
    heroHits(round: 2, damage: 4, enemyHealthAfter: 16),
    enemyHits(round: 2, damage: 7, heroHealthAfter: 16),
    heroHits(round: 3, damage: 4, enemyHealthAfter: 12),
    enemyHits(round: 3, damage: 7, heroHealthAfter: 9),
    heroHits(round: 4, damage: 4, enemyHealthAfter: 8),
    enemyHits(round: 4, damage: 7, heroHealthAfter: 2),
    heroHits(round: 5, damage: 4, enemyHealthAfter: 4),
    enemyHits(round: 5, damage: 2, heroHealthAfter: 0),
  ];

  static List<FightTurnEntity> defeatByBruteFullyGeared() => [
    heroHits(round: 1, damage: 7, enemyHealthAfter: 48),
    enemyHits(round: 1, damage: 21, heroHealthAfter: 54),
    heroHits(round: 2, damage: 9, enemyHealthAfter: 39),
    enemyHits(round: 2, damage: 24, heroHealthAfter: 30),
    heroHits(round: 3, damage: 8, enemyHealthAfter: 31),
    enemyHits(round: 3, damage: 24, heroHealthAfter: 6),
    heroHits(round: 4, damage: 8, enemyHealthAfter: 23),
    enemyHits(round: 4, damage: 6, heroHealthAfter: 0),
  ];
}
