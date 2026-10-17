import '../../../../core/config/constants/enum/enemy_kind.dart';
import '../../../../core/config/constants/enum/skill_id.dart';

extension EnemyKindRules on EnemyKind {
  Set<SkillId> get skills => switch (this) {
    EnemyKind.bandit => const {SkillId.dodge},
    EnemyKind.barbarian => const {SkillId.doubleStrike},
    EnemyKind.barbarianChief => const {SkillId.doubleStrike, SkillId.secondWind},
    EnemyKind.wolf => const {SkillId.doubleStrike},
    EnemyKind.bear => const {SkillId.doubleStrike},
    EnemyKind.banditVeteran => const {SkillId.dodge},
  };
}
