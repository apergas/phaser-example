import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/layers/presentation/features/arena/models/arena_result_data.dart';

abstract final class ArenaResultDataMock {
  static ArenaResultData get victoryTenGold => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaVictory,
    detail: Internationalize.arenaReward(amount: 10),
  );

  static ArenaResultData get championHundredGold => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaChampion,
    detail: Internationalize.arenaReward(amount: 100),
  );

  static ArenaResultData get victoryThirtyThreeGold => ArenaResultData(
    isVictory: true,
    title: Internationalize.arenaVictory,
    detail: Internationalize.arenaReward(amount: 33),
  );

  static ArenaResultData get defeatNeedAttack => ArenaResultData(
    isVictory: false,
    title: Internationalize.arenaDefeat,
    detail: Internationalize.arenaAdvice(advice: FightAdvice.needAttack),
  );
}
