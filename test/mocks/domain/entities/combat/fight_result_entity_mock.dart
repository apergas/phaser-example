import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/layers/domain/entities/combat/fight_result_entity.dart';

import 'fight_log_entity_mock.dart';

abstract final class FightResultEntityMock {
  static const FightLockedEntity locked = FightLockedEntity();

  static FightPlayedEntity victoryOverBandit() => FightPlayedEntity(log: FightLogEntityMock.victoryOverBandit());

  static FightPlayedEntity almostBeatDuelist() =>
      FightPlayedEntity(log: FightLogEntityMock.almostBeatDuelist(), advice: FightAdvice.almostThere);
}
