import '../../../../../core/config/constants/enum/fight_side.dart';
import '../../../../../core/config/constants/enum/skill_id.dart';

sealed class ArenaEffect {
  const ArenaEffect();
}

final class HitEffect extends ArenaEffect {
  final FightSide side;
  final int index;
  final int damage;

  const HitEffect({required this.side, required this.index, required this.damage});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HitEffect && other.side == side && other.index == index && other.damage == damage;

  @override
  int get hashCode => Object.hash(HitEffect, side, index, damage);
}

final class DodgeEffect extends ArenaEffect {
  final FightSide side;
  final int index;

  const DodgeEffect({required this.side, required this.index});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DodgeEffect && other.side == side && other.index == index;

  @override
  int get hashCode => Object.hash(DodgeEffect, side, index);
}

final class HealEffect extends ArenaEffect {
  final FightSide side;
  final int index;
  final int amount;

  const HealEffect({required this.side, required this.index, required this.amount});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealEffect && other.side == side && other.index == index && other.amount == amount;

  @override
  int get hashCode => Object.hash(HealEffect, side, index, amount);
}

final class FightEndedEffect extends ArenaEffect {
  final bool isVictory;

  const FightEndedEffect({required this.isVictory});

  @override
  bool operator ==(Object other) => identical(this, other) || other is FightEndedEffect && other.isVictory == isVictory;

  @override
  int get hashCode => Object.hash(FightEndedEffect, isVictory);
}

final class SkillUsedEffect extends ArenaEffect {
  final SkillId skill;

  const SkillUsedEffect({required this.skill});

  @override
  bool operator ==(Object other) => identical(this, other) || other is SkillUsedEffect && other.skill == skill;

  @override
  int get hashCode => Object.hash(SkillUsedEffect, skill);
}
