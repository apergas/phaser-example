import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/arena/arena_level_item_status.dart';
import 'package:farming/core/config/constants/enum/arena/power_tone.dart';
import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/core/config/constants/enum/enemy_kind.dart';
import 'package:farming/layers/presentation/features/arena/models/arena_level_item_data.dart';

import '../../../domain/world/funds_mock.dart';

abstract final class ArenaLevelItemDataMock {
  static ArenaLevelItemData get rookieOpen => ArenaLevelItemData(
    id: ArenaLevelId.banditRookie,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditRookie),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
    powerText: Internationalize.arenaPower(power: 19),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amounts: FundsMock.tenGold),
    status: ArenaLevelItemStatus.open,
  );

  static ArenaLevelItemData get rookieCleared => ArenaLevelItemData(
    id: ArenaLevelId.banditRookie,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditRookie),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.bandit),
    powerText: Internationalize.arenaPower(power: 19),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amounts: FundsMock.threeGold),
    status: ArenaLevelItemStatus.cleared,
  );

  static ArenaLevelItemData get veteranLocked => ArenaLevelItemData(
    id: ArenaLevelId.banditVeteran,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditVeteran),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.banditVeteran),
    powerText: Internationalize.arenaPower(power: 41),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amounts: FundsMock.thirtyGold),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get veteranOpen => ArenaLevelItemData(
    id: ArenaLevelId.banditVeteran,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditVeteran),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.banditVeteran),
    powerText: Internationalize.arenaPower(power: 41),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amounts: FundsMock.thirtyGold),
    status: ArenaLevelItemStatus.open,
  );

  static ArenaLevelItemData get trioLocked => ArenaLevelItemData(
    id: ArenaLevelId.banditTrio,
    name: Internationalize.arenaLevel(id: ArenaLevelId.banditTrio),
    enemiesText: Internationalize.arenaEnemyCount(count: 3, name: Internationalize.arenaEnemy(kind: EnemyKind.bandit)),
    powerText: Internationalize.arenaPower(power: 123),
    tone: PowerTone.hard,
    rewardText: Internationalize.arenaReward(amounts: FundsMock.banditTrioReward),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get wolfLocked => ArenaLevelItemData(
    id: ArenaLevelId.wolf,
    name: Internationalize.arenaLevel(id: ArenaLevelId.wolf),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
    powerText: Internationalize.arenaPower(power: 29),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amounts: FundsMock.twentyGold),
    status: ArenaLevelItemStatus.locked,
  );

  static ArenaLevelItemData get wolfOpen => ArenaLevelItemData(
    id: ArenaLevelId.wolf,
    name: Internationalize.arenaLevel(id: ArenaLevelId.wolf),
    enemiesText: Internationalize.arenaEnemy(kind: EnemyKind.wolf),
    powerText: Internationalize.arenaPower(power: 29),
    tone: PowerTone.easy,
    rewardText: Internationalize.arenaReward(amounts: FundsMock.twentyGold),
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
    rewardText: Internationalize.arenaReward(amounts: FundsMock.barbarianChiefReward),
    status: ArenaLevelItemStatus.locked,
  );
}
