import '../../../core/config/constants/enum/tree_kind.dart';
import '../entities/tree/tree_stats_entity.dart';

abstract final class Rules {
  static const double chopIntervalMs = 750;
  static const double hammerIntervalMs = 650;
  static const double mineIntervalMs = 750;
  static const double depositIntervalMs = 400;
  static const double quarryMineIntervalMs = 525;
  static const double workGap = 2;
  static const double reachTolerance = 6;
  static const double pickUpRange = 14;
  static const double playerSpeed = 110;
  static const double playerRadius = 8;
  static const double treeTrunkRadius = 12;
  static const double sproutAfterMs = 60000;
  static const double regrowAfterMs = 180000;
  static const double rockRadius = 22;
  static const int rockStoneYield = 8;
  static const int rockHitsToBreak = 8;
  static const int carryCapacity = 10;
  static const double quarryRockRange = 120;
  static const double quarryBoostRange = 160;
  static const int upgradedHitsPercent = 60;
  static const double autosaveIntervalMs = 10000;
  static const Map<TreeKind, TreeStatsEntity> treeKindStats = {
    TreeKind.slim: TreeStatsEntity(woodYield: 4, hitsToFell: 3),
    TreeKind.round: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.wide: TreeStatsEntity(woodYield: 6, hitsToFell: 5),
    TreeKind.broad: TreeStatsEntity(woodYield: 6, hitsToFell: 5),
    TreeKind.twisted: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.branches: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.leaning: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.lumpy: TreeStatsEntity(woodYield: 5, hitsToFell: 5),
    TreeKind.pine: TreeStatsEntity(woodYield: 4, hitsToFell: 3),
    TreeKind.dome: TreeStatsEntity(woodYield: 6, hitsToFell: 5),
    TreeKind.oak: TreeStatsEntity(woodYield: 8, hitsToFell: 7),
    TreeKind.dense: TreeStatsEntity(woodYield: 6, hitsToFell: 5),
    TreeKind.old: TreeStatsEntity(woodYield: 9, hitsToFell: 8),
    TreeKind.big: TreeStatsEntity(woodYield: 9, hitsToFell: 8),
  };
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
