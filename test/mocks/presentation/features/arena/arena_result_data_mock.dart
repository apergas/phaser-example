import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/fight_advice.dart';
import 'package:farming/layers/presentation/features/arena/models/arena_result_data.dart';

import '../../../domain/world/funds_mock.dart';

abstract final class ArenaResultDataMock {
  static ArenaResultData get victoryTenGold => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaVictory,
    detail: Internationalize.arenaReward(amounts: FundsMock.tenGold),
  );

  static ArenaResultData get championWithTheChiefReward => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaChampion,
    detail: Internationalize.arenaReward(amounts: FundsMock.barbarianChiefReward),
  );

  static ArenaResultData get victoryWithTheChiefRepeatReward => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaVictory,
    detail: Internationalize.arenaReward(amounts: FundsMock.barbarianChiefRepeatReward),
  );

  static ArenaResultData get defeatNeedAttack => ArenaResultData(
    isVictory: false,
    title: Internationalize.arenaDefeat,
    detail: Internationalize.arenaAdvice(advice: FightAdvice.needAttack),
  );
}
