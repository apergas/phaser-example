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

abstract final class Combat {
  static FightLogEntity resolve({
    required ArenaLevelEntity level,
    required CombatStatsEntity heroStats,
    required Set<SkillId> skills,
    required int seed,
  }) {
    final fight = _Fight(level: level, heroStats: heroStats, skills: skills, random: SeededRandom(seed))..play();
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
    final strikes = log.turns.where((turn) => turn.actor == FightSide.hero && turn.target == FightSide.enemy).toList();
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
  final Set<SkillId> skills;
  final SeededRandom random;
  final List<FightTurnEntity> turns = [];
  final List<int> enemyHealth;
  int heroHealth;
  int heroAttacks = 0;
  int round = 0;
  bool secondWindUsed = false;

  _Fight({required this.level, required this.heroStats, required this.skills, required this.random})
    : enemyHealth = [for (final enemy in level.enemies) enemy.stats.health],
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
    if (skills.contains(SkillId.doubleStrike) && heroAttacks % Rules.doubleStrikeEvery == 0) {
      _heroStrikes(FightAction.doubleStrike);
    }
  }

  void _heroStrikes(FightAction action) {
    final target = enemyHealth.indexWhere((health) => health > 0);
    if (target < 0) return;
    final damage = _damage(
      attack: heroStats.attack,
      defense: level.enemies[target].stats.defense,
      healthLeft: enemyHealth[target],
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
  }

  void _enemiesAttack() {
    for (var index = 0; index < level.enemies.length; index++) {
      if (heroHealth == 0) return;
      if (enemyHealth[index] == 0) continue;
      _enemyStrikes(index);
      _catchSecondWind();
    }
  }

  void _enemyStrikes(int index) {
    final dodged = skills.contains(SkillId.dodge) && random.next() < Rules.dodgeChance;
    final damage = dodged
        ? 0
        : _damage(attack: level.enemies[index].stats.attack, defense: heroStats.defense, healthLeft: heroHealth);
    heroHealth -= damage;
    turns.add(
      FightTurnEntity(
        round: round,
        actor: FightSide.enemy,
        actorIndex: index,
        target: FightSide.hero,
        targetIndex: 0,
        action: dodged ? FightAction.dodge : FightAction.hit,
        damage: damage,
        targetHealthAfter: heroHealth,
      ),
    );
  }

  void _catchSecondWind() {
    if (!skills.contains(SkillId.secondWind) || secondWindUsed) return;
    if (heroHealth == 0 || heroHealth >= heroStats.health * Rules.secondWindThreshold) return;
    secondWindUsed = true;
    heroHealth = math.min(heroStats.health, heroHealth + (heroStats.health * Rules.secondWindHeal).round());
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

  int _damage({required int attack, required int defense, required int healthLeft}) {
    final spread = 1 + (random.next() * 2 - 1) * Rules.damageSpread;
    return math.min(healthLeft, math.max(1, ((attack - defense) * spread).round()));
  }
}
