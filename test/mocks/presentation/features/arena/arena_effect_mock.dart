import 'package:rpg/core/config/constants/enum/fight_side.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_effect.dart';

abstract final class ArenaEffectMock {
  static const HitEffect banditHitForFour = HitEffect(side: FightSide.enemy, index: 0, damage: 4);

  static const HitEffect heroHitForTwo = HitEffect(side: FightSide.hero, index: 0, damage: 2);

  static const HitEffect banditHitForThree = HitEffect(side: FightSide.enemy, index: 0, damage: 3);

  static const HitEffect banditHitForFive = HitEffect(side: FightSide.enemy, index: 0, damage: 5);

  static const HitEffect heroHitForOne = HitEffect(side: FightSide.hero, index: 0, damage: 1);

  static const HitEffect heroHitForThree = HitEffect(side: FightSide.hero, index: 0, damage: 3);

  static const DodgeEffect heroDodged = DodgeEffect(side: FightSide.hero, index: 0);

  static const HealEffect heroHealedTwelve = HealEffect(side: FightSide.hero, index: 0, amount: 12);

  static const SkillUsedEffect doubleStrikeUsed = SkillUsedEffect(skill: SkillId.doubleStrike);

  static const SkillUsedEffect doubleStrikeUsedCopy = SkillUsedEffect(skill: SkillId.doubleStrike);

  static const SkillUsedEffect secondWindUsed = SkillUsedEffect(skill: SkillId.secondWind);

  static const FightEndedEffect won = FightEndedEffect(isVictory: true);

  static const ChampionEffect champion = ChampionEffect();

  static const FightEndedEffect lost = FightEndedEffect(isVictory: false);

  static const List<ArenaEffect> victoryOverBandit = [
    banditHitForThree,
    heroHitForOne,
    banditHitForFive,
    heroHitForThree,
    banditHitForFour,
    heroHitForTwo,
    banditHitForFour,
    heroHitForTwo,
    banditHitForFour,
    won,
  ];
}
