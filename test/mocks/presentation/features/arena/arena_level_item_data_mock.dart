import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/arena/arena_level_item_status.dart';
import 'package:rpg/core/config/constants/enum/arena/power_tone.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_level_item_data.dart';

abstract final class ArenaLevelItemDataMock {
  static ArenaLevelItemData get rookieOpen => ArenaLevelItemData(
    id: ArenaLevelId.banditRookie,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditRookie),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
    powerText: Internationalize.arenaPower(power: 19),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amount: 10),
    status: ArenaLevelItemStatus.open,
  );

  static ArenaLevelItemData get rookieCleared => ArenaLevelItemData(
    id: ArenaLevelId.banditRookie,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditRookie),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
    powerText: Internationalize.arenaPower(power: 19),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amount: 3),
    status: ArenaLevelItemStatus.cleared,
  );

  static ArenaLevelItemData get veteranLocked => ArenaLevelItemData(
    id: ArenaLevelId.banditVeteran,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditVeteran),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.banditVeteran),
    powerText: Internationalize.arenaPower(power: 41),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amount: 30),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get veteranOpen => ArenaLevelItemData(
    id: ArenaLevelId.banditVeteran,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditVeteran),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.banditVeteran),
    powerText: Internationalize.arenaPower(power: 41),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amount: 30),
    status: ArenaLevelItemStatus.open,
  );

  static ArenaLevelItemData get trioLocked => ArenaLevelItemData(
    id: ArenaLevelId.banditTrio,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditTrio),
    enemiesText: Internationalize.arenaEnemyCount(count: 3, name: Internationalize.arenaEnemy(kind: EnemyKind.bandit)),
    powerText: Internationalize.arenaPower(power: 123),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amount: 75),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get wolfLocked => ArenaLevelItemData(
    id: ArenaLevelId.wolf,
    name: Internationalize.arenaLevel(id: ArenaLevelId.wolf),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
    powerText: Internationalize.arenaPower(power: 29),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amount: 20),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get wolfOpen => ArenaLevelItemData(
    id: ArenaLevelId.wolf,
    name: Internationalize.arenaLevel(id: ArenaLevelId.wolf),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
    powerText: Internationalize.arenaPower(power: 29),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amount: 20),
    status: ArenaLevelItemStatus.open,
  );

  static ArenaLevelItemData get chiefLocked => ArenaLevelItemData(
    id: ArenaLevelId.barbarianChief,
    name: Internationalize.arenaLevel(id: ArenaLevelId.barbarianChief),
    enemiesText: [
      Internationalize.arenaEnemy(kind: EnemyKind.barbarianChief),
      Internationalize.arenaEnemyCount(count: 2, name: Internationalize.arenaEnemy(kind: EnemyKind.barbarian)),
    ].join(', '),
    powerText: Internationalize.arenaPower(power: 210),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amount: 150),
    status: ArenaLevelItemStatus.locked,
  );
}
