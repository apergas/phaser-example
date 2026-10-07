import 'package:rpg/layers/presentation/features/arena/models/fight_replay_data.dart';

import '../../../domain/entities/combat/fight_log_entity_mock.dart';

abstract final class FightReplayDataMock {
  static FightReplayData victoryOverBanditStart() => FightReplayData.start(FightLogEntityMock.victoryOverBandit());

  static FightReplayData allActionsStart() => FightReplayData.start(FightLogEntityMock.allActions());
}
