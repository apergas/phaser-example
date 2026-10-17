abstract final class Rules {
  static const int hitsToFellTree = 5;
  static const double chopIntervalMs = 750;
  static const double hammerIntervalMs = 650;
  static const double workGap = 2;
  static const double reachTolerance = 6;
  static const double pickUpRange = 14;
  static const double playerSpeed = 110;
  static const double playerRadius = 8;
  static const double treeTrunkRadius = 12;
  static const double powerPerSkill = 0.1;
  static const int maxFightRounds = 30;
  static const List<double> dodgeChanceByLevel = [0.2, 0.25, 0.3];
  static const double secondWindThreshold = 0.3;
  static const List<double> secondWindHealByLevel = [0.4, 0.5, 0.6];
  static const int doubleStrikeEvery = 3;
  static const List<double> doubleStrikeBonusByLevel = [0, 0.15, 0.3];
  static const int enemySkillLevel = 1;
  static const double almostThereShare = 0.25;
  static const double weakHitDamage = 2;
  static const int repeatRewardDivisor = 3;
}
