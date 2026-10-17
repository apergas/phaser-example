import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../../../core/config/constants/enum/fight_action.dart';
import '../../../core/config/constants/enum/fight_advice.dart';
import '../../../core/config/constants/enum/fight_outcome.dart';
import '../../../core/config/constants/enum/fight_side.dart';
import '../../../core/config/constants/enum/skill_id.dart';
import '../../../core/utils/seeded_random.dart';
import '../entities/combat/arena_level_entity.dart';
import '../entities/combat/enemy_entity.dart';
import '../entities/combat/fight_log_entity.dart';
import '../entities/combat/fight_turn_entity.dart';
import '../entities/hero/combat_stats_entity.dart';
import '../rules/rules.dart';
import '../world/extensions/enemy_kind_rules.dart';

abstract final class Combat {
  static FightLogEntity resolve({
    required ArenaLevelEntity level,
    required CombatStatsEntity heroStats,
    required Map<SkillId, int> skillLevels,
    required int seed,
  }) {
    final fight = _Fight(level: level, heroStats: heroStats, skillLevels: skillLevels, random: SeededRandom(seed))
      ..play();
    return FightLogEntity(
      levelId: level.id,
      heroStats: heroStats,
      enemies: level.enemies,
      turns: List.unmodifiable(fight.turns),
      outcome: fight.enemiesDefeated ? FightOutcome.victory : FightOutcome.defeat,
      reward: const {},
    );
  }

  static FightAdvice? adviceFor(FightLogEntity log) {
    if (log.isVictory) return null;
    final totalHealth = log.enemies.fold(0, (sum, enemy) => sum + enemy.stats.health);
    final healthLeft = log.enemies.indexed.fold(0, (sum, entry) => sum + _healthLeft(log, entry.$1, entry.$2));
    if (healthLeft <= totalHealth * Rules.almostThereShare) return FightAdvice.almostThere;
    final strikes = log.turns
        .where(
          (turn) => turn.actor == FightSide.hero && turn.target == FightSide.enemy && turn.action != FightAction.dodge,
        )
        .toList();
    final totalDamage = strikes.fold(0, (sum, turn) => sum + turn.damage);
    final averageDamage = strikes.isEmpty ? 0.0 : totalDamage / strikes.length;
    if (averageDamage <= Rules.weakHitDamage) return FightAdvice.needAttack;
    return FightAdvice.needDefense;
  }

  static int _healthLeft(FightLogEntity log, int index, EnemyEntity enemy) {
    final lastHit = log.turns.lastWhereOrNull((turn) => turn.target == FightSide.enemy && turn.targetIndex == index);
    return lastHit?.targetHealthAfter ?? enemy.stats.health;
  }
}

final class _Fight {
  final ArenaLevelEntity level;
  final CombatStatsEntity heroStats;
  final Map<SkillId, int> skillLevels;
  final SeededRandom random;
  final List<FightTurnEntity> turns = [];
  final List<int> enemyHealth;
  final List<bool> enemySecondWindUsed;
  int heroHealth;
  int heroAttacks = 0;
  int round = 0;
  bool secondWindUsed = false;

  _Fight({required this.level, required this.heroStats, required this.skillLevels, required this.random})
    : enemyHealth = [for (final enemy in level.enemies) enemy.stats.health],
      enemySecondWindUsed = [for (final _ in level.enemies) false],
      heroHealth = heroStats.health;

  bool get enemiesDefeated => enemyHealth.every((health) => health == 0);

  bool get isOver => heroHealth == 0 || enemiesDefeated || round == Rules.maxFightRounds;

  void play() {
    while (!isOver) {
      round++;
      _heroAttacks();
      _enemiesAttack();
    }
  }

  void _heroAttacks() {
    _heroStrikes(FightAction.hit);
    heroAttacks++;
    if (_levelOf(SkillId.doubleStrike) > 0 && heroAttacks % Rules.doubleStrikeEvery == 0) {
      _heroStrikes(FightAction.doubleStrike);
    }
  }

  void _heroStrikes(FightAction action) {
    final target = enemyHealth.indexWhere((health) => health > 0);
    if (target < 0) return;
    if (_enemyRolls(SkillId.dodge, target)) {
      turns.add(
        FightTurnEntity(
          round: round,
          actor: FightSide.hero,
          actorIndex: 0,
          target: FightSide.enemy,
          targetIndex: target,
          action: FightAction.dodge,
          damage: 0,
          targetHealthAfter: enemyHealth[target],
        ),
      );
      return;
    }
    final damage = _damage(
      attacker: heroStats,
      defense: level.enemies[target].stats.defense,
      healthLeft: enemyHealth[target],
      bonus: action == FightAction.doubleStrike
          ? Rules.doubleStrikeBonusByLevel[_levelOf(SkillId.doubleStrike) - 1]
          : 0,
    );
    enemyHealth[target] -= damage;
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.hero,
        actorIndex: 0,
        target: FightSide.enemy,
        targetIndex: target,
        action: action,
        damage: damage,
        targetHealthAfter: enemyHealth[target],
      ),
    );
    _catchEnemySecondWind(target);
  }

  void _enemiesAttack() {
    for (var index = 0; index < level.enemies.length; index++) {
      if (heroHealth == 0) return;
      if (enemyHealth[index] == 0) continue;
      _enemyStrikes(index, FightAction.hit);
      _catchSecondWind();
      if (heroHealth > 0 && _enemyRolls(SkillId.doubleStrike, index)) {
        _enemyStrikes(index, FightAction.doubleStrike);
        _catchSecondWind();
      }
    }
  }

  void _enemyStrikes(int index, FightAction action) {
    final dodgeLevel = _levelOf(SkillId.dodge);
    final dodged = dodgeLevel > 0 && random.next() < Rules.dodgeChanceByLevel[dodgeLevel - 1];
    final damage = dodged
        ? 0
        : _damage(attacker: level.enemies[index].stats, defense: heroStats.defense, healthLeft: heroHealth);
    heroHealth -= damage;
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.enemy,
        actorIndex: index,
        target: FightSide.hero,
        targetIndex: 0,
        action: dodged ? FightAction.dodge : action,
        damage: damage,
        targetHealthAfter: heroHealth,
      ),
    );
  }

  void _catchSecondWind() {
    final secondWindLevel = _levelOf(SkillId.secondWind);
    if (secondWindLevel == 0 || secondWindUsed) return;
    if (heroHealth == 0 || heroHealth >= heroStats.health * Rules.secondWindThreshold) return;
    secondWindUsed = true;
    heroHealth = math.min(
      heroStats.health,
      heroHealth + (heroStats.health * Rules.secondWindHealByLevel[secondWindLevel - 1]).round(),
    );
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.hero,
        actorIndex: 0,
        target: FightSide.hero,
        targetIndex: 0,
        action: FightAction.secondWind,
        damage: 0,
        targetHealthAfter: heroHealth,
      ),
    );
  }

  void _catchEnemySecondWind(int index) {
    final enemy = level.enemies[index];
    if (!enemy.kind.skills.contains(SkillId.secondWind) || enemySecondWindUsed[index]) return;
    if (enemyHealth[index] == 0 || enemyHealth[index] >= enemy.stats.health * Rules.secondWindThreshold) return;
    enemySecondWindUsed[index] = true;
    if (!_enemyRolls(SkillId.secondWind, index)) return;
    enemyHealth[index] = math.min(
      enemy.stats.health,
      enemyHealth[index] + (enemy.stats.health * Rules.secondWindHealByLevel[Rules.enemySkillLevel - 1]).round(),
    );
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.enemy,
        actorIndex: index,
        target: FightSide.enemy,
        targetIndex: index,
        action: FightAction.secondWind,
        damage: 0,
        targetHealthAfter: enemyHealth[index],
      ),
    );
  }

  int _levelOf(SkillId skill) => skillLevels[skill] ?? 0;

  bool _enemyRolls(SkillId skill, int index) =>
      level.enemySkillChance > 0 &&
      level.enemies[index].kind.skills.contains(skill) &&
      random.next() < level.enemySkillChance;

  int _damage({
    required CombatStatsEntity attacker,
    required int defense,
    required int healthLeft,
    double bonus = 0,
  }) {
    final attack = attacker.attackMin + (random.next() * (attacker.attackMax - attacker.attackMin + 1)).floor();
    final hit = math.max(1, attack - defense);
    return math.min(healthLeft, (hit * (1 + bonus)).round());
  }
}
